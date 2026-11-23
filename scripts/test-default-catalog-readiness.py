import importlib.util
from pathlib import Path
import unittest

path = Path(__file__).with_name('verify-default-catalog.py')
spec = importlib.util.spec_from_file_location('catalog_ready', path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class DefaultCatalogReadiness(unittest.TestCase):
    def setUp(self):
        self.source = {'url': 'https://github.com/PastureStack/catalog-templates.git', 'branch': 'main',
                       'pinnedCommit': '6e7b935b6f08e711e1884ef8369cd9dcd110901f',
                       'requiredTemplates': [{'base': 'infra', 'name': name, 'revision': revision}
                           for name, revision in [('healthcheck', 7), ('ipsec-overlay', 17), ('network-services', 16), ('resource-scheduler', 10)]]}
        self.responses = {'/v1-catalog/catalogs/pasturestack': dict(self.source, commit=self.source['pinnedCommit'])}
        for required in self.source['requiredTemplates']:
            template = 'pasturestack:infra*' + required['name']
            for kind, identity in [('templates', template), ('templateversions', template + ':' + str(required['revision']))]:
                self.responses['/v1-catalog/' + kind + '/' + identity + '?rancherVersion=v1.6.603'] = {'id': identity}

    def test_all_exact_deployed_versions_are_verified(self):
        self.assertEqual(module.verify_source(self.source, 'pasturestack', 'v1.6.603', self.responses.__getitem__), 8)

    def test_nonempty_stale_index_is_never_ready(self):
        self.responses['/v1-catalog/catalogs/pasturestack']['commit'] = '0' * 40
        with self.assertRaisesRegex(RuntimeError, 'indexed commit'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.603', self.responses.__getitem__)

    def test_same_commit_missing_exact_version_is_not_ready(self):
        def read(path):
            if '/templateversions/' in path:
                raise RuntimeError('Catalog exact API is not HTTP 200')
            return self.responses[path]
        with self.assertRaisesRegex(RuntimeError, 'HTTP 200'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.603', read)

    def test_another_version_response_cannot_replace_deployed_version(self):
        for key in self.responses:
            if '/templateversions/' in key:
                self.responses[key] = {'id': 'pasturestack:infra*healthcheck:1'}
                break
        with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.603', self.responses.__getitem__)


if __name__ == '__main__':
    unittest.main()
