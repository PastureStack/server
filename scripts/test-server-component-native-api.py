"""Local fake-curl checks for the shared official-asset byte transport."""
from pathlib import Path
import hashlib
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'server/artifacts/fetch-server-component.sh'
BASH = ('C:/msys64/usr/bin/bash.exe' if os.name == 'nt' else shutil.which('bash'))
BODY = b'complete official fixture bytes\n'
SHA = hashlib.sha256(BODY).hexdigest()


def shell_path(path):
    value = Path(path).resolve().as_posix()
    return '/' + value[0].lower() + value[2:] if os.name == 'nt' else value


class NativeAssetTransportTest(unittest.TestCase):
    def run_case(self, headers, expected=SHA, url='https://api.github.com/repos/PastureStack/example/releases/assets/123', body=BODY):
        self.assertTrue(BASH and Path(BASH).is_file(), 'native Bash required; never invoke WSL')
        with tempfile.TemporaryDirectory(prefix='asset-api-local-') as folder:
            work = Path(folder)
            (work/'body').write_bytes(body)
            (work/'headers').write_bytes(headers.encode())
            (work/'curl').write_text('''#!/usr/bin/env bash
set -euo pipefail
printf '%s\\n' "$@" > "$MOCK_LOG"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dump-header) headers=$2; shift 2 ;;
    *) shift ;;
  esac
done
cp "$MOCK_HEADERS" "$headers"
cat "$MOCK_BODY"
''', encoding='utf-8', newline='\n')
            env = {k:v for k,v in os.environ.items() if k.casefold() != 'path'}
            env.update(PATH=shell_path(work)+':/usr/bin:/bin', MOCK_LOG=shell_path(work/'args'),
                       MOCK_BODY=shell_path(work/'body'), MOCK_HEADERS=shell_path(work/'headers'))
            result = subprocess.run([BASH, '-c', 'chmod +x "$1"; bash "$2" remote "$3" fixture.bin "$4" "$5"',
                'fixture', shell_path(work/'curl'), shell_path(HELPER), url, expected, shell_path(work/'out')],
                env=env, capture_output=True, timeout=20)
            args = (work/'args').read_text().splitlines() if (work/'args').exists() else []
            self.assertEqual(list(work.glob('out.headers.*')), [], 'only own header temporary is removed')
            return result.returncode, args, result.stderr.decode(errors='replace')

    def test_official_api_200_or_complete_206_and_redirects(self):
        for headers in (
            'HTTP/2 200\r\nContent-Length: '+str(len(BODY))+'\r\n\r\n',
            'HTTP/2 302\r\nContent-Length: 0\r\n\r\nHTTP/2 206\r\nContent-Length: '+str(len(BODY))+'\r\nContent-Range: bytes 0-'+str(len(BODY)-1)+'/'+str(len(BODY))+'\r\n\r\n'):
            code, args, error = self.run_case(headers)
            self.assertEqual(code, 0, error)
            self.assertIn('Accept: application/octet-stream', args)
            self.assertIn('Range: bytes=0-', args)
            self.assertIn('--disable', args)
            self.assertIn('--proto', args)
            self.assertIn('=https', args)
            self.assertIn('--proto-redir', args)
            self.assertIn('--max-filesize', args)
            self.assertNotIn('--insecure', args)
            self.assertFalse(any('Authorization:' in value or 'Cookie:' in value for value in args))

    def test_partial_or_missing_range_wrong_length_and_http_error_are_rejected(self):
        for headers in (
            'HTTP/2 206\r\n\r\n',
            'HTTP/2 206\r\nContent-Range: bytes 1-'+str(len(BODY))+'/'+str(len(BODY)+1)+'\r\n\r\n',
            'HTTP/2 206\r\nContent-Range: bytes 0-4/100\r\n\r\n',
            'HTTP/2 200\r\nContent-Length: 999\r\n\r\n',
            'HTTP/2 503\r\n\r\n'):
            code, _, _ = self.run_case(headers)
            self.assertNotEqual(code, 0)

    def test_sha_and_https_remain_mandatory(self):
        headers = 'HTTP/2 200\r\nContent-Length: '+str(len(BODY))+'\r\n\r\n'
        self.assertNotEqual(self.run_case(headers, expected='0'*64)[0], 0)
        code, args, _ = self.run_case(headers, url='http://untrusted.example/asset')
        self.assertNotEqual(code, 0)
        self.assertEqual(args, [])

    def test_exact_shared_jdk_and_component_api_sources_are_wired(self):
        api = 'https://api.github.com/repos/'
        main = (ROOT/'server/Dockerfile').read_text(encoding='utf-8')
        docker = (ROOT/'server/Dockerfile.web-compose-release').read_text(encoding='utf-8')
        codeql = (ROOT/'.github/workflows/codeql.yml').read_text(encoding='utf-8')
        build = (ROOT/'server/build-api-explorer-patch-image.sh').read_text(encoding='utf-8')
        for source in (main, docker, codeql):
            self.assertIn('https://github.com/adoptium/temurin25-binaries/releases/download/'
                          'jdk-25.0.5%2B8/OpenJDK25U-jdk_x64_linux_hotspot_25.0.5_8.tar.gz', source)
            self.assertIn('68982529869257d0ee6b824ec5aa270ff8b118bb438670da0b97ebdab178d7fb', source)
            self.assertIn('fetch-server-component', source)
        for source in (docker, build):
            self.assertIn(api+'PastureStack/orchestration-engine/releases/assets/733683735', source)
            self.assertIn(api+'PastureStack/compose-cli/releases/assets/741756962', source)
            self.assertIn(api+'PastureStack/web-console/releases/assets/734661689', source)
            self.assertIn(api+'PastureStack/web-console/releases/assets/734661683', source)
            self.assertIn('WEB_CONSOLE_ASSET_API_URL', source)
            self.assertIn('WEB_CONSOLE_SBOM_ASSET_API_URL', source)
        self.assertIn('"${WEB_CONSOLE_ASSET_API_URL}"', docker)
        self.assertIn('"${WEB_CONSOLE_SBOM_ASSET_API_URL}"', docker)
        self.assertIn('asset_api_url="$(read_arg ORCHESTRATION_ENGINE_ASSET_API_URL)"', codeql)
        self.assertIn('"$asset_api_url" "$artifact" "$expected_sha256" "$archive"', codeql)
        self.assertNotIn('--output "$archive" "$release_base/$release_tag/$artifact"', codeql)


if __name__ == '__main__':
    unittest.main()
