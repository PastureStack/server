import importlib.util
import json
from pathlib import Path
import re
import unittest

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
spec = importlib.util.spec_from_file_location('compose_identity', HERE / 'check_compose_release_identity.py')
owner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(owner)


class ComposeReleaseIdentity(unittest.TestCase):
    def setUp(self):
        self.review = json.loads((HERE / 'reviews/compose-0.14.46-openpgp.json').read_text())
        a = self.review['artifact']
        self.values = dict(version=a['releaseVersion'], source=a['source'],
                           archive=a['releaseGzipSha256'], binary=a['binarySha256'])

    def test_original_reviewed_identity(self):
        self.assertEqual(owner.validate(self.review, **self.values)['source'], self.values['source'])

    def test_only_registered_review_can_be_selected(self):
        self.assertEqual(owner.load_review('0.14.46'), self.review)
        self.assertEqual(owner.load_review('0.14.45')['artifact']['releaseVersion'], '0.14.45')
        for value in ('../README.md', '/etc/passwd', '', '0.14.999'):
            with self.assertRaisesRegex(ValueError, 'ComposeReleaseIdentityReviewRequired'):
                owner.load_review(value)

    def test_old_producer_cannot_label_new_binary(self):
        self.values['source'] = '10a9279c79542ff7b221715baade93e5e644da90'
        with self.assertRaisesRegex(ValueError, 'ComposeReleaseIdentityMismatch:source'):
            owner.validate(self.review, **self.values)

    def test_each_missing_or_changed_coordinate_rejected(self):
        for field in self.values:
            for bad in (None, '', '0' * (40 if field == 'source' else 64)):
                with self.subTest(field=field, bad=bad):
                    values = dict(self.values, **{field: bad})
                    with self.assertRaises(ValueError):
                        owner.validate(self.review, **values)

    def test_actual_recipe_and_build_defaults_use_one_reviewed_identity(self):
        docker = (ROOT / 'server/Dockerfile.web-compose-release').read_text()
        build = (ROOT / 'server/build-api-explorer-patch-image.sh').read_text()
        fields = {'version': 'VERSION', 'source': 'COMMIT',
                  'archive': 'ARCHIVE_SHA256', 'binary': 'BINARY_SHA256'}
        docker_values, build_values = {}, {}
        for key, suffix in fields.items():
            marker = 'COMPOSE_EXECUTOR_' + suffix
            matches = re.findall(r'^ARG ' + marker + r'=(\S+)$', docker, re.M)
            self.assertTrue(matches)
            self.assertEqual(1, len(set(matches)))
            docker_values[key] = matches[0]
            defaults = re.findall(r'^compose_executor_' + suffix.lower() + r'=\$\{' + marker + r':-([^}]+)\}$', build, re.M)
            self.assertEqual(1, len(defaults))
            build_values[key] = defaults[0]
        owner.validate(self.review, **docker_values)
        owner.validate(self.review, **build_values)
        self.assertIn('check_compose_release_identity.py', build)
        self.assertLess(build.index('check_compose_release_identity.py'), build.index('docker build'))


if __name__ == '__main__':
    unittest.main()
