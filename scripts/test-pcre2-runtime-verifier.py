"""Source guards for the final-image verifier; native execution belongs to QA."""
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / 'server/artifacts/verify-pcre2-runtime.sh'


class Pcre2RuntimeVerifier(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = SCRIPT.read_text(encoding='utf-8')

    def test_exact_first_party_versions_and_dpkg_integrity(self):
        self.assertIn('expected_version=10.46-1build1+pasturestack.1', self.text)
        self.assertIn('for package in libpcre2-8-0 libpcre2-posix3;', self.text)
        self.assertIn("${db:Status-Status}\\t${Version}\\n", self.text)
        self.assertIn('dpkg --verify libpcre2-8-0 libpcre2-posix3', self.text)
        self.assertRegex(self.text, r'if test -s "\$temporary/dpkg-verify"; then\s+'
                                   r'cat "\$temporary/dpkg-verify" >&2\s+exit 1\s+fi')
        # The installer must retain package files; this verifier never ignores
        # missing documentation or filters a real ELF discrepancy.
        self.assertNotIn('README.Debian', self.text)

    def test_manifest_is_exact_and_binds_resolved_runtime_files(self):
        for required in ['manifest=/usr/share/pasturestack/security/pcre2-runtime.sha256',
                         'NF != 2', 'length($1) != 64', '$1 ~ /[^0-9a-f]/', 'NR != 2',
                         'test "$count_pcre2:$count_posix" = 1:1',
                         'sha256sum --check "$manifest"',
                         'resolved=$(readlink -f -- "$file")']:
            self.assertIn(required, self.text)

    def test_all_five_consumers_resolve_the_verified_pcre2(self):
        match = re.search(r'for consumer in (.*?);\s*do\b', self.text, re.S)
        self.assertIsNotNone(match)
        consumers = match[1].replace('\\\n', ' ').split()
        self.assertEqual(['/usr/bin/grep', '/usr/bin/git', '/usr/sbin/mariadbd',
                          '/usr/lib/x86_64-linux-gnu/libselinux.so.1',
                          '/usr/lib/x86_64-linux-gnu/libpcre2-posix.so.3'], consumers)
        self.assertIn('ldd -r "$consumer"', self.text)
        self.assertIn('not found|undefined symbol', self.text)
        self.assertIn('if (count != 1) exit 1', self.text)
        self.assertIn('test "$(readlink -f -- "$linked")" = "$pcre2"', self.text)

    def test_minimal_real_grep_git_controls_cover_both_locales_and_interpreter(self):
        for required in ['for test_locale in C C.utf8;', "for prefix in '' '(*NO_JIT)';",
                         '${prefix}^ASCII$', '${prefix}(*UTF)^漢字$', '${prefix}^CRLF\\r$',
                         "/usr/bin/git -C /usr/lib grep --no-index -P '^ID=ubuntu$' -- os-release",
                         'cmp "$temporary/os-release" "$temporary/actual"']:
            self.assertIn(required, self.text)
        self.assertIn("printf 'ASCII\\n漢字\\nCRLF\\r\\n'", self.text)

    def test_readback_never_installs_tools_or_opens_database(self):
        self.assertNotRegex(self.text, r'(?m)^\s*(?:apt(?:-get)?|pip[0-9]*|python[0-9]*|readelf|nm)\b')
        self.assertNotIn('dpkg --install', self.text)
        self.assertNotRegex(self.text, r'(?m)^\s*/usr/sbin/mariadbd\b')
        self.assertIn('mktemp -d /tmp/pcre2-runtime.XXXXXXXX', self.text)
        self.assertIn('set -eu', self.text)
        self.assertTrue(self.text.rstrip().endswith('echo PCRE2_RUNTIME_BACKPORT_OK'))


if __name__ == '__main__':
    unittest.main()
