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
                       'pinnedCommit': '8c1c28318580d5ec18c14a13b224ce0e02e40bf8',
                       'requiredTemplates': [{'base': 'infra', 'name': name, 'revision': revision}
                           for name, revision in [('healthcheck', 7), ('ipsec-overlay', 17), ('network-services', 16), ('resource-scheduler', 10),
                                                  ('container-crontab', 3), ('container-crontab', 4), ('container-schedule', 4)]]}
        self.responses = {'/v1-catalog/catalogs/pasturestack': dict(self.source, commit=self.source['pinnedCommit'])}
        for required in self.source['requiredTemplates']:
            namespaces = ('pasturestack', 'library') if required['name'] == 'container-crontab' else ('pasturestack',)
            for namespace in namespaces:
                template = namespace + ':infra*' + required['name']
                for kind, identity in [('templates', template), ('templateversions', template + ':' + str(required['revision']))]:
                    self.responses['/v1-catalog/' + kind + '/' + identity + '?rancherVersion=v1.6.604'] = {'id': identity}

    def test_all_exact_deployed_versions_are_verified(self):
        self.assertEqual(module.verify_source(self.source, 'pasturestack', 'v1.6.604', self.responses.__getitem__), 18)

    def test_nonempty_stale_index_is_never_ready(self):
        self.responses['/v1-catalog/catalogs/pasturestack']['commit'] = '0' * 40
        with self.assertRaisesRegex(RuntimeError, 'indexed commit'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.604', self.responses.__getitem__)

    def test_same_commit_missing_exact_version_is_not_ready(self):
        def read(path):
            if '/templateversions/' in path:
                raise RuntimeError('Catalog exact API is not HTTP 200')
            return self.responses[path]
        with self.assertRaisesRegex(RuntimeError, 'HTTP 200'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.604', read)

    def test_another_version_response_cannot_replace_deployed_version(self):
        for key in self.responses:
            if '/templateversions/' in key:
                self.responses[key] = {'id': 'pasturestack:infra*healthcheck:1'}
                break
        with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.604', self.responses.__getitem__)

    def test_legacy_alias_is_required_for_both_previous_and_current_revision(self):
        for revision in (3, 4):
            with self.subTest(revision=revision):
                path = '/v1-catalog/templateversions/library:infra*container-crontab:' + str(revision) + '?rancherVersion=v1.6.604'
                def read(requested):
                    if requested == path:
                        raise RuntimeError('Catalog exact API is not HTTP 200')
                    return self.responses[requested]
                with self.assertRaisesRegex(RuntimeError, 'HTTP 200'):
                    module.verify_source(self.source, 'pasturestack', 'v1.6.604', read)

    def test_legacy_alias_must_preserve_library_namespace(self):
        path = '/v1-catalog/templateversions/library:infra*container-crontab:3?rancherVersion=v1.6.604'
        self.responses[path] = {'id': 'pasturestack:infra*container-crontab:3'}
        with self.assertRaisesRegex(RuntimeError, 'identity mismatch'):
            module.verify_source(self.source, 'pasturestack', 'v1.6.604', self.responses.__getitem__)


if __name__ == '__main__':
    unittest.main()
