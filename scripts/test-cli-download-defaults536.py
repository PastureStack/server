"""Focused CLI download defaults and operator override contract, no network IO."""
import os,pathlib,re,subprocess,sys,unittest
ROOT=pathlib.Path(__file__).resolve().parents[1]
RECIPE=(ROOT/'server/Dockerfile.web-compose-release').read_text()
BUILD=(ROOT/'server/build-api-explorer-patch-image.sh').read_text()
CATTLE=(ROOT/'server/artifacts/cattle.sh').read_text()
FUNCTION=re.search(r'^setup_cli_artifact_overrides\(\)\n\{.*?^\}',CATTLE,re.M|re.S).group()
DEFAULTS=dict(re.findall(r'^ENV ((?:DEFAULT_CATTLE_RANCHER_CLI_[A-Z]+_URL|CATTLE_RANCHER_CLI_VERSION))=(\S+)$',RECIPE,re.M))
class CliDefaults536(unittest.TestCase):
 def evaluate(self,overrides=None):
  env={'PATH':os.environ['PATH'],'RC16_ARTIFACT_BASE_URL':'https://legacy.example/releases/v1.6.278',**DEFAULTS,**(overrides or {})}
  script=FUNCTION+'\nsetup_cli_artifact_overrides\n'+ '\n'.join('printf "%s\\n" "${'+k+'}"'for k in sorted(DEFAULTS))
  process=subprocess.run(['bash','-c',script],env=env,capture_output=True,text=True,timeout=10)
  self.assertEqual(process.returncode,0)
  return dict(zip(sorted(DEFAULTS),process.stdout.splitlines()))
 def test_numeric_version_and_three_official_default_urls(self):
  self.assertEqual(DEFAULTS['CATTLE_RANCHER_CLI_VERSION'],'v0.6.18')
  for platform,suffix in [('LINUX','linux-amd64.tar.gz'),('DARWIN','darwin-amd64.tar.gz'),('WINDOWS','windows-amd64.zip')]:
   key='DEFAULT_CATTLE_RANCHER_CLI_'+platform+'_URL'
   self.assertEqual(DEFAULTS[key],'https://github.com/PastureStack/cli/releases/download/v0.6.18/pasturestack-cli-0.6.18-'+suffix)
   self.assertIn(key+'='+DEFAULTS[key],BUILD)
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_clean_defaults_do_not_use_legacy_artifact_base(self):
  self.assertEqual(self.evaluate(),DEFAULTS)
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_operator_default_url_override_is_preserved(self):
  custom={'DEFAULT_CATTLE_RANCHER_CLI_LINUX_URL':'https://mirror.example/owned-cli.tar.gz'}
  self.assertEqual(self.evaluate(custom),{**DEFAULTS,**custom})
 @unittest.skipIf(sys.platform=='win32','Run Bash semantics in the Linux release gate; do not launch WSL')
 def test_operator_active_url_is_not_rewritten(self):
  key='CATTLE_RANCHER_CLI_LINUX_URL';custom='https://mirror.example/active-cli.tar.gz'
  script=FUNCTION+'\nsetup_cli_artifact_overrides\nprintf "%s" "${'+key+'}"'
  p=subprocess.run(['bash','-c',script],env={'PATH':os.environ['PATH'],'RC16_ARTIFACT_BASE_URL':'https://legacy.example',**DEFAULTS,key:custom},capture_output=True,text=True,timeout=10)
  self.assertEqual((p.returncode,p.stdout),(0,custom))
if __name__=='__main__':unittest.main()
