"""Focused CLI download defaults and operator override contract, no network IO."""
import os,pathlib,re,subprocess,sys,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
RECIPE=(ROOT/'server/Dockerfile.web-compose-release').read_text()
BUILD=(ROOT/'server/build-api-explorer-patch-image.sh').read_text()
CATTLE=(ROOT/'server/artifacts/cattle.sh').read_text()
FUNCTION=re.search(r'^setup_cli_artifact_overrides\(\)\n\{.*?^\}',CATTLE,re.M|re.S).group()
DEFAULTS=dict(re.findall(r'^ENV ((?:PASTURESTACK_CLI_RELEASE_BASE_URL|CATTLE_RANCHER_CLI_VERSION))=(\S+)$',RECIPE,re.M))
URLS=['DEFAULT_CATTLE_RANCHER_CLI_'+x+'_URL'for x in ('LINUX','DARWIN','WINDOWS')]
KEYS=['CATTLE_RANCHER_CLI_VERSION',*URLS]
def expected(version='0.6.20',base='https://github.com/PastureStack/cli/releases/download'):
 return dict(zip(URLS,[base+'/v'+version+'/pasturestack-cli-'+p+'-'+version+suffix for p,suffix in [('linux-amd64','.tar.gz'),('darwin-amd64','.tar.gz'),('windows-amd64','.zip')]]))
class CliDefaults536(unittest.TestCase):
 def evaluate(self,overrides=None,*,no_compose=False):
  env={'PATH':os.environ['PATH'],'RC16_ARTIFACT_BASE_URL':'https://legacy.example/releases/v1.6.278',**DEFAULTS,**(overrides or {})}
  script='set -eu\n'+FUNCTION+'\nsetup_cli_artifact_overrides\n'
  if no_compose:script+='test "${CATTLE_RANCHER_COMPOSE_VERSION+x}" != x\n'
  script+='\n'.join('printf "%s\\n" "${'+k+'}"'for k in KEYS)
  process=subprocess.run(['bash','-c',script],env=env,capture_output=True,text=True,timeout=10)
  self.assertEqual(process.returncode,0)
  return dict(zip(KEYS,process.stdout.splitlines()))
 def test_numeric_version_and_three_official_default_urls(self):
  self.assertEqual(DEFAULTS['CATTLE_RANCHER_CLI_VERSION'],'v0.6.20')
  self.assertEqual(DEFAULTS['PASTURESTACK_CLI_RELEASE_BASE_URL'],'https://github.com/PastureStack/cli/releases/download')
  for key,value in DEFAULTS.items():self.assertIn(key+'='+value,BUILD)
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_clean_defaults_do_not_use_legacy_artifact_base(self):
  self.assertEqual(self.evaluate(),{'CATTLE_RANCHER_CLI_VERSION':'v0.6.20',**expected()})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_operator_default_url_override_is_preserved(self):
  custom={'DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL':'https://mirror.example/owned-cli.tar.gz'}
  self.assertEqual(self.evaluate(custom),{'CATTLE_RANCHER_CLI_VERSION':'v0.6.20',**expected(),**custom})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_version_only_override_changes_all_three_urls(self):
  self.assertEqual(self.evaluate({'CATTLE_RANCHER_CLI_VERSION':'v0.6.17'}),{'CATTLE_RANCHER_CLI_VERSION':'v0.6.17',**expected('0.6.17')})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_legacy_base_without_new_release_base_keeps_historical_layout(self):
  result=self.evaluate({'PASTURESTACK_CLI_RELEASE_BASE_URL':'','CATTLE_RANCHER_CLI_VERSION':'v0.6.14'})
  self.assertEqual(result,{'CATTLE_RANCHER_CLI_VERSION':'v0.6.14',**dict(zip(URLS,['https://legacy.example/releases/v1.6.278/pasturestack-cli-0.6.14-'+p for p in ('linux-amd64.tar.gz','darwin-amd64.tar.gz','windows-amd64.zip')]))})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_modern_release_base_does_not_need_legacy_base(self):
  self.assertEqual(self.evaluate({'RC16_ARTIFACT_BASE_URL':''},no_compose=True),{'CATTLE_RANCHER_CLI_VERSION':'v0.6.20',**expected()})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_operator_active_url_is_not_rewritten(self):
  key='CATTLE_RANCHER_CLI_LINUX_URL';custom='https://mirror.example/active-cli.tar.gz'
  script=FUNCTION+'\nsetup_cli_artifact_overrides\nprintf "%s" "${'+key+'}"'
  p=subprocess.run(['bash','-c',script],env={'PATH':os.environ['PATH'],'RC16_ARTIFACT_BASE_URL':'https://legacy.example',**DEFAULTS,key:custom},capture_output=True,text=True,timeout=10)
  self.assertEqual((p.returncode,p.stdout),(0,custom))
if __name__=='__main__':unittest.main()
