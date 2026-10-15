#!/usr/bin/env python3
"""Exercise the production VEX jq predicate against exact curl fix mutations."""
import copy
import json
from pathlib import Path
import re
import subprocess
import unittest


ROOT = Path(__file__).resolve().parents[1]
GATE = (ROOT / 'scripts/check-server-api-explorer-patch.sh').read_text(encoding='utf-8')
VEX = json.loads((ROOT / 'server/security/openvex.json').read_text(encoding='utf-8'))
CURL_CVES = {
    'CVE-2026-107928', 'CVE-2026-107929', 'CVE-2026-86409', 'CVE-2026-86410',
    'CVE-2026-86412', 'CVE-2026-86414', 'CVE-2026-87862', 'CVE-2026-87863',
    'CVE-2026-87864', 'CVE-2026-87865', 'CVE-2026-92386', 'CVE-2026-92387',
    'CVE-2026-92388', 'CVE-2026-92389', 'CVE-2026-92390', 'CVE-2026-92391',
    'CVE-2026-92392', 'CVE-2026-94266',
}
PURLS = {'pkg:deb/ubuntu/' + package + '@8.18.0-1ubuntu2.8?arch=amd64&distro=ubuntu-26.04'
         for package in ('curl', 'libcurl3t64-gnutls', 'libcurl4t64')}
HASHES = (
    '2c418a61d7165d0cde01d9cb05ae025cc41fc75ef6d3f095996bd045ba0945dc',
    '8db913e1fa5a694ca6ba7b828bd18c5204e6853ac07fe7ed9c6e1f94e3444d8e',
    '7c0b37592f83a629cc22f0c98effa176da9edbd6d77b3f38184a9d0ddc5e0266',
)


class CurlFixedVexTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        expressions = re.findall(r"jq -e '(\n.*?)\n' \"\$runtime_vex\" >/dev/null", GATE, re.S)
        if len(expressions) != 1:
            raise AssertionError('Expected the single actual production VEX predicate')
        cls.expression = expressions[0]
        cls.indices = [index for index, item in enumerate(VEX['statements'])
                       if item['vulnerability']['name'] in CURL_CVES]

    def gate_accepts(self, document):
        result = subprocess.run(['jq', '-e', self.expression], input=json.dumps(document),
                                text=True, capture_output=True, check=False)
        self.assertNotIn('jq: error:', result.stderr, result.stderr)
        return result.returncode == 0

    def test_actual_gate_accepts_only_the_eighteen_exact_official_fixes(self):
        self.assertEqual(len(self.indices), 18)
        self.assertEqual(len(VEX['statements']), 69)
        self.assertTrue(self.gate_accepts(VEX))
        for index in self.indices:
            statement = VEX['statements'][index]
            self.assertEqual(statement['status'], 'fixed')
            self.assertNotIn('justification', statement)
            self.assertEqual({product['@id'] for product in statement['products']}, PURLS)
            self.assertEqual(len(statement['products']), 3)
            self.assertIn('https://ubuntu.com/security/notices/USN-8927-1', statement['impact_statement'])
            self.assertIn(statement['vulnerability']['name'], statement['impact_statement'])
            for digest in HASHES:
                self.assertIn(digest, statement['impact_statement'])

    def test_not_affected_is_rejected_for_every_new_fixed_cve(self):
        for index in self.indices:
            with self.subTest(cve=VEX['statements'][index]['vulnerability']['name']):
                mutated = copy.deepcopy(VEX)
                mutated['statements'][index]['status'] = 'not_affected'
                mutated['statements'][index]['justification'] = 'vulnerable_code_not_present'
                self.assertFalse(self.gate_accepts(mutated))

    def test_old_versions_and_missing_packages_are_rejected_for_every_fix(self):
        for index in self.indices:
            for package in range(3):
                for mutation in ('old-version', 'missing-package'):
                    with self.subTest(cve=VEX['statements'][index]['vulnerability']['name'],
                                      package=package, mutation=mutation):
                        mutated = copy.deepcopy(VEX)
                        products = mutated['statements'][index]['products']
                        if mutation == 'old-version':
                            products[package]['@id'] = products[package]['@id'].replace('ubuntu2.8', 'ubuntu2.7')
                        else:
                            products.pop(package)
                        self.assertFalse(self.gate_accepts(mutated))

    def test_unknown_cves_and_wildcard_products_are_rejected(self):
        unknown = copy.deepcopy(VEX['statements'][self.indices[0]])
        unknown['vulnerability']['name'] = 'CVE-2026-99999999'
        for append in (False, True):
            mutated = copy.deepcopy(VEX)
            if append:
                mutated['statements'].append(unknown)
            else:
                mutated['statements'][self.indices[0]] = unknown
            self.assertFalse(self.gate_accepts(mutated))
        mutated = copy.deepcopy(VEX)
        mutated['statements'][self.indices[0]]['products'][0]['@id'] = 'pkg:deb/ubuntu/curl@*'
        self.assertFalse(self.gate_accepts(mutated))

    def test_untraceable_fix_statements_are_rejected(self):
        evidence = (*HASHES, 'https://ubuntu.com/security/notices/USN-8927-1',
                    'https://github.com/curl/curl/commit/', 'debian/patches/')
        for index in self.indices:
            for marker in evidence:
                with self.subTest(cve=VEX['statements'][index]['vulnerability']['name'], evidence=marker):
                    mutated = copy.deepcopy(VEX)
                    statement = mutated['statements'][index]
                    statement['impact_statement'] = statement['impact_statement'].replace(marker, 'REMOVED')
                    self.assertFalse(self.gate_accepts(mutated))


if __name__ == '__main__':
    unittest.main(verbosity=2)
