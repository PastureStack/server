"""Focused fixed-recovery policy tests; no API, build, image or scanner invocation."""
import argparse,copy,importlib.util,json,sys,unittest
from pathlib import Path
import server583_publication_recovery_policy as p
spec=importlib.util.spec_from_file_location('complete583',Path(__file__).with_name('complete-server583-publication.py'));owner=importlib.util.module_from_spec(spec);spec.loader.exec_module(owner)
parser=argparse.ArgumentParser(add_help=False);parser.add_argument('--original-evidence',type=Path);args,remaining=parser.parse_known_args();sys.argv=[sys.argv[0],*remaining]
def fixture():
 steps=[{'name':n,'conclusion':'success','number':i+1,'completed_at':'2026-11-07T14:25:00Z'}for i,n in enumerate(p.PASSED)]
 steps +=[{'name':'Attest image provenance','conclusion':'failure','number':10},{'name':'Attest image SBOM','conclusion':'skipped','number':11},{'name':'Create immutable GitHub Release','conclusion':'skipped','number':12},{'name':'Clean run-owned resources','conclusion':'success','number':13}]
 run={'id':p.RUN,'head_sha':p.SOURCE,'run_attempt':1,'event':'workflow_dispatch','path':p.ORIGINAL_WORKFLOW,'status':'completed','conclusion':'failure'}
 job={'id':p.JOB,'run_id':p.RUN,'head_sha':p.SOURCE,'run_attempt':1,'name':'publish','conclusion':'failure','started_at':'2026-11-07T14:20:02Z','steps':steps}
 artifact={'id':p.ARTIFACT,'name':'server-'+p.TAG+'-publication-'+str(p.RUN),'size_in_bytes':p.ARTIFACT_BYTES,'digest':'sha256:'+p.ARTIFACT_SHA,'workflow_run':{'id':p.RUN,'head_sha':p.SOURCE},'expired':False}
 return run,{'total_count':1,'jobs':[job]},b'InternalError: error creating tlog entry - (500) unexpected result from transparency log',artifact

def verified(recovery,kind,predicate):
 cert={'issuer':'https://token.actions.githubusercontent.com','subjectAlternativeName':p.SIGNER,'buildSignerURI':p.SIGNER,'buildSignerDigest':recovery['source'],'sourceRepositoryURI':'https://github.com/'+p.REPO,'sourceRepositoryDigest':recovery['source'],'sourceRepositoryRef':'refs/heads/main','buildConfigURI':p.SIGNER,'buildConfigDigest':recovery['source'],'runInvocationURI':recovery['invocation'],'runnerEnvironment':'github-hosted'}
 return [{'verificationResult':{'signature':{'certificate':cert},'verifiedTimestamps':[{'type':'Tlog'}],'statement':{'_type':'https://in-toto.io/Statement/v1','subject':[{'name':p.IMAGE,'digest':{'sha256':p.DIGEST[7:]}}],'predicateType':kind,'predicate':predicate}}}]
class CompletionPolicy(unittest.TestCase):
 def test_original_tlog_only_and_all_build_security_steps_remain_required(self):
  data=fixture();p.validate_original(*data)
  for name in p.PASSED:
   bad=copy.deepcopy(data);next(x for x in bad[1]['jobs'][0]['steps']if x['name']==name)['conclusion']='failure'
   with self.subTest(name=name),self.assertRaises(ValueError):p.validate_original(*bad)
  for field,value in [('head_sha','0'*40),('conclusion','success'),('run_attempt',2)]:
   bad=copy.deepcopy(data);bad[0][field]=value
   with self.subTest(field=field),self.assertRaises(ValueError):p.validate_original(*bad)
  with self.assertRaises(ValueError):p.validate_original(data[0],data[1],b'403 permission denied',data[3])
 def test_exact_artifact_no_substitution(self):
  data=fixture()
  for field,value in [('id',1),('size_in_bytes',1),('digest','sha256:'+'0'*64),('expired',True)]:
   bad=copy.deepcopy(data);bad[3][field]=value
   with self.subTest(field=field),self.assertRaises(ValueError):p.validate_original(*bad)
 def test_builder_and_recovery_signer_are_distinct_and_both_bound(self):
  data=fixture();job=p.validate_original(*data);r=p.recovery_identity('a'*40,123456,1);pred=p.predicate(job,r)
  self.assertEqual(pred['runDetails']['builder']['id'],p.BUILDER);self.assertNotEqual(p.BUILDER,p.SIGNER)
  self.assertEqual(pred['buildDefinition']['externalParameters']['originalBuild']['source'],p.SOURCE)
  rows=verified(r,p.PROVENANCE,pred);p.validate_verified(rows,p.PROVENANCE,r,pred)
  cert_fields=('issuer','subjectAlternativeName','buildSignerURI','buildSignerDigest','sourceRepositoryDigest','sourceRepositoryRef','buildConfigURI','buildConfigDigest','runInvocationURI','runnerEnvironment')
  for field in cert_fields:
   bad=copy.deepcopy(rows);bad[0]['verificationResult']['signature']['certificate'][field]='wrong'
   with self.subTest(field=field),self.assertRaises(ValueError):p.validate_verified(bad,p.PROVENANCE,r,pred)
  for mutate in (lambda x:x[0]['verificationResult']['verifiedTimestamps'].clear(),lambda x:x[0]['verificationResult']['statement']['subject'][0]['digest'].update(sha256='0'*64),lambda x:x[0]['verificationResult']['statement']['predicate']['runDetails']['builder'].update(id=p.SIGNER),lambda x:x[0]['verificationResult']['statement']['predicate']['buildDefinition']['externalParameters']['originalBuild'].update(source=r['source'])):
   bad=copy.deepcopy(rows);mutate(bad)
   with self.assertRaises(ValueError):p.validate_verified(bad,p.PROVENANCE,r,pred)
 def test_sbom_exact_and_signer_command_never_claims_original_certificate_source(self):
  r=p.recovery_identity('a'*40,123456,2);body={'bomFormat':'CycloneDX','original':True};rows=verified(r,p.SBOM,body);p.validate_verified(rows,p.SBOM,r,body)
  bad=copy.deepcopy(rows);bad[0]['verificationResult']['statement']['predicate']['original']=False
  with self.assertRaises(ValueError):p.validate_verified(bad,p.SBOM,r,body)
  cmd=p.verify_command(p.DIGEST,p.SBOM,r)
  for flag,value in [('--signer-digest',r['source']),('--source-digest',r['source']),('--signer-workflow',p.REPO+'/'+p.RECOVERY_WORKFLOW)]:self.assertEqual(cmd[cmd.index(flag)+1],value)
  p.validate_verify_argv(cmd)
  with self.assertRaises(ValueError):p.validate_verify_argv(cmd+['--signer-repo',p.REPO])
  with self.assertRaises(ValueError):p.validate_verify_argv([x for x in cmd if x!='--source-digest'])
  with self.assertRaises(ValueError):p.recovery_identity(p.SOURCE,123456,1)
 def test_recovery_source_only_closed_additions_and_signed_original(self):
  commit={'sha':p.SOURCE,'tree':{'sha':p.TREE},'verification':{'verified':True,'reason':'valid'}}
  comparison={'base_commit':{'sha':p.SOURCE},'merge_base_commit':{'sha':p.SOURCE},'status':'ahead','files':[{'filename':n,'status':'added'}for n in p.FILES]}
  p.validate_source(commit,comparison)
  bad=copy.deepcopy(comparison);bad['files'].append({'filename':'server/Dockerfile.web-compose-release','status':'modified'})
  with self.assertRaises(ValueError):p.validate_source(commit,bad)
  bad=copy.deepcopy(commit);bad['verification']['verified']=False
  with self.assertRaises(ValueError):p.validate_source(bad,comparison)
 def test_workflow_no_image_mutations_and_all_crypto_steps_precede_release(self):
  text=Path(__file__).resolve().parents[1].joinpath('.github/workflows/complete-server583-publication.yml').read_text()
  self.assertEqual(text.count('actions/attest@1e69f48acb82d1966a394da916b4c1698aa569d6'),2)
  self.assertIn('predicate-path:',text);self.assertIn('sbom-path:',text)
  self.assertLess(text.index('Attest original image SBOM'),text.index('Complete exact immutable release'))
  self.assertNotIn('docker build',text);self.assertNotIn('docker push',text);self.assertNotIn('docker pull',text)
  self.assertEqual(len(owner.NAMES),35)
 def test_real_collected_original_when_provided(self):
  if args.original_evidence is None:self.skipTest('Optional actual-byte reader not a CI fixture')
  root=args.original_evidence;p.validate_original(json.loads((root/'run-original.json').read_bytes()),json.loads((root/'jobs-original.json').read_bytes()),(root/'job-original.log').read_bytes(),json.loads((root/'artifact-original.json').read_bytes()))
  rows=owner.validate_archive((root/'original-publication-evidence.zip').read_bytes());self.assertEqual(owner.sha(rows['server.cdx.json']),owner.SBOM_SHA)
  self.assertNotIn('release-notes.md',rows)
if __name__=='__main__':unittest.main()
