"""Focused fixed-recovery policy tests; no API, build, image or scanner invocation."""
import argparse,contextlib,copy,importlib.util,json,sys,unittest,io,zipfile,subprocess
from pathlib import Path
from unittest import mock
import server583_publication_recovery_policy as p
spec=importlib.util.spec_from_file_location('complete583',Path(__file__).with_name('complete-server583-publication.py'));owner=importlib.util.module_from_spec(spec);spec.loader.exec_module(owner)
parser=argparse.ArgumentParser(add_help=False);parser.add_argument('--original-evidence',type=Path);parser.add_argument('--official-attempt-archive',type=Path);args,remaining=parser.parse_known_args();sys.argv=[sys.argv[0],*remaining]
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
 def test_oci_bundle_source_keeps_exact_verification_argv(self):
  r=p.recovery_identity('a'*40,123456,1)
  for kind in (p.PROVENANCE,p.SBOM):
   expected=['gh','attestation','verify','oci://'+p.IMAGE+'@'+p.DIGEST,'--bundle-from-oci','--repo',p.REPO,
    '--signer-workflow',p.REPO+'/'+p.RECOVERY_WORKFLOW,'--signer-digest',r['source'],
    '--source-digest',r['source'],'--source-ref','refs/heads/main','--predicate-type',kind,'--format','json']
   command=p.verify_command(p.DIGEST,kind,r);self.assertEqual(command,expected)
   for bad in ([x for x in command if x!='--bundle-from-oci'],command+['--bundle-from-oci'],command+['--bundle','untrusted-local.json']):
    with self.subTest(kind=kind,command=bad),self.assertRaises(ValueError):p.validate_verify_argv(bad)
 def test_oci_verify_uses_private_anonymous_child_config_only(self):
  recovery=p.recovery_identity('a'*40,123456,1);directories=[]
  def child(*command,**kwargs):
   self.assertEqual(command,tuple(p.verify_command(p.DIGEST,kind,recovery)))
   env=kwargs['env'];self.assertEqual(env['GH_TOKEN'],'EXPLICIT_UNIT_TOKEN');self.assertNotEqual(env['DOCKER_CONFIG'],'ambient-authenticated-config')
   config=Path(env['DOCKER_CONFIG']);directories.append(config)
   self.assertEqual(json.loads((config/'config.json').read_bytes()),{'auths':{}});self.assertEqual(set(x.name for x in config.iterdir()),{'config.json'})
   self.assertEqual(owner.os.environ['DOCKER_CONFIG'],'ambient-authenticated-config')
   return b'unit-verified-by-command; full policy check remains in caller'
  with mock.patch.dict(owner.os.environ,{'DOCKER_CONFIG':'ambient-authenticated-config','GH_TOKEN':'EXPLICIT_UNIT_TOKEN'}),mock.patch.object(owner,'command',side_effect=child):
   for kind in (p.PROVENANCE,p.SBOM):self.assertTrue(owner.anonymous_oci_verify(kind,recovery))
   self.assertEqual(owner.os.environ['DOCKER_CONFIG'],'ambient-authenticated-config')
  self.assertEqual(len(directories),2);self.assertTrue(all(not x.exists()for x in directories))
 def test_command_failure_emits_only_safe_categories_and_still_fails_closed(self):
  stderr=b'error: docker-credential-desktop not found; unauthorized; HTTP 503; invalid argument; verification failed; no matching attestations; Authorization: Bearer SECRET_TOKEN; Location: https://download/?sig=SECRET_SAS'
  result=subprocess.CompletedProcess([],1,b'{"body":"SECRET_BODY"}',stderr);out=io.StringIO()
  with mock.patch.object(owner.subprocess,'run',return_value=result)as run,contextlib.redirect_stdout(out),self.assertRaises(ValueError)as failure:
   owner.command('gh','attestation','verify','oci://unit',env={'DOCKER_CONFIG':'unit-only'})
  detail=json.loads(out.getvalue())['requiredCommandFailure'];self.assertEqual(detail['exitCode'],1);self.assertEqual(detail['httpStatus'],503)
  self.assertTrue(all(detail[x]for x in('ociAttestationVerify','credentialHelperUnavailable','authenticationFailure','attestationUnavailable','cryptographicVerificationFailure','invalidArgument','serverError')))
  self.assertTrue(all(value is None or type(value)in(int,bool)for value in detail.values()))
  self.assertEqual(run.call_args.kwargs['env'],{'DOCKER_CONFIG':'unit-only'})
  for secret in ('SECRET_TOKEN','SECRET_SAS','SECRET_BODY','Authorization','Location','https://','oci://unit'):self.assertNotIn(secret,out.getvalue()+str(failure.exception))
  for error,field in ((subprocess.TimeoutExpired(['sensitive-command'],1,output=b'SECRET_BODY',stderr=stderr),'timedOut'),(FileNotFoundError('SECRET_PATH'),'launchFailed')):
   out=io.StringIO()
   with mock.patch.object(owner.subprocess,'run',side_effect=error),contextlib.redirect_stdout(out),self.assertRaises(ValueError):owner.command('gh','attestation','verify','oci://unit')
   detail=json.loads(out.getvalue())['requiredCommandFailure'];self.assertTrue(detail[field]);self.assertIsNone(detail['exitCode']);self.assertNotIn('SECRET',out.getvalue())
  out=io.StringIO()
  with mock.patch.object(owner.subprocess,'run',return_value=subprocess.CompletedProcess([],0,b'xx',b'')),contextlib.redirect_stdout(out),self.assertRaises(ValueError):owner.command('gh','api','unit',cap=1)
  self.assertTrue(json.loads(out.getvalue())['requiredCommandFailure']['stdoutCapExceeded'])
  with mock.patch.object(owner.subprocess,'run',return_value=subprocess.CompletedProcess([],0,b'ok',b''))as run:
   self.assertEqual(owner.command('gh','api','unit'),b'ok');self.assertIsNone(run.call_args.kwargs['env'])
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
  self.assertEqual(pred['originalBuildProvenance']['predicate']['runDetails']['builder']['id'],p.BUILDER);self.assertNotEqual(p.BUILDER,p.SIGNER)
  self.assertEqual(pred['originalBuild']['source'],p.SOURCE)
  rows=verified(r,p.PROVENANCE,pred);p.validate_verified(rows,p.PROVENANCE,r,pred)
  cert_fields=('issuer','subjectAlternativeName','buildSignerURI','buildSignerDigest','sourceRepositoryDigest','sourceRepositoryRef','buildConfigURI','buildConfigDigest','runInvocationURI','runnerEnvironment')
  for field in cert_fields:
   bad=copy.deepcopy(rows);bad[0]['verificationResult']['signature']['certificate'][field]='wrong'
   with self.subTest(field=field),self.assertRaises(ValueError):p.validate_verified(bad,p.PROVENANCE,r,pred)
  for mutate in (lambda x:x[0]['verificationResult']['verifiedTimestamps'].clear(),lambda x:x[0]['verificationResult']['statement']['subject'][0]['digest'].update(sha256='0'*64),lambda x:x[0]['verificationResult']['statement']['predicate']['originalBuildProvenance']['predicate']['runDetails']['builder'].update(id=p.SIGNER),lambda x:x[0]['verificationResult']['statement']['predicate']['originalBuild'].update(source=r['source'])):
   bad=copy.deepcopy(rows);mutate(bad)
   with self.assertRaises(ValueError):p.validate_verified(bad,p.PROVENANCE,r,pred)
 def test_recovery_predicate_uri_consistent_and_bounded(self):
  expected='https://github.com/PastureStack/server#recovery-v1'
  self.assertEqual(p.PROVENANCE,expected);self.assertEqual(p.MAX_RECOVERY_PREDICATE_TYPE_BYTES,64);self.assertLessEqual(len(p.PROVENANCE.encode('utf-8')),p.MAX_RECOVERY_PREDICATE_TYPE_BYTES)
  root=Path(__file__).resolve().parents[1]
  workflow=(root/'.github/workflows/complete-server583-publication.yml').read_text()
  self.assertEqual(workflow.count('predicate-type: '+expected),1)
  document=(root/'docs/operations/server583-publication-recovery.md').read_text();self.assertIn('## Recovery v1',document);self.assertIn('`'+expected+'`',document)
  recovery=p.recovery_identity('a'*40,123456,1);command=p.verify_command(p.DIGEST,p.PROVENANCE,recovery)
  self.assertEqual(command[command.index('--predicate-type')+1],expected)
 def test_custom_recovery_is_not_claimed_as_original_native_slsa(self):
  data=fixture();job=p.validate_original(*data);r=p.recovery_identity('a'*40,123456,1);body=p.predicate(job,r)
  self.assertNotEqual(p.PROVENANCE,p.SLSA_PROVENANCE);self.assertFalse(body['originalNativeSlsaAvailable'])
  original=body['originalBuildProvenance'];self.assertFalse(original['originalSignatureAvailable'])
  self.assertEqual(original['evidenceStatus'],'RECONSTRUCTED_FROM_ORIGINAL_OFFICIAL_RECORDS_NOT_ORIGINAL_SIGNED_PROVENANCE')
  self.assertEqual(original['predicateType'],p.SLSA_PROVENANCE)
  self.assertEqual(original['predicate']['buildDefinition']['buildType'],'https://actions.github.io/buildtypes/workflow/v1')
  self.assertEqual(original['predicate']['buildDefinition']['externalParameters']['workflow'],{'repository':'https://github.com/'+p.REPO,'path':p.ORIGINAL_WORKFLOW,'ref':'refs/heads/main'})
  self.assertEqual(body['originalBuild']['conclusion'],'failure');self.assertEqual(body['originalArtifact']['sha256'],p.ARTIFACT_SHA)
  self.assertEqual(body['originalBuild']['passedBuildSecurityPublishSteps'],list(p.PASSED));self.assertEqual(body['RecoverySigner'],r)
  rows=verified(r,p.PROVENANCE,body);p.validate_verified(rows,p.PROVENANCE,r,body)
  with self.assertRaises(ValueError):p.verify_command(p.DIGEST,p.SLSA_PROVENANCE,r)
  with self.assertRaises(ValueError):p.validate_verified(verified(r,p.SLSA_PROVENANCE,body),p.SLSA_PROVENANCE,r,body)
  for field,value in [('originalNativeSlsaAvailable',True),('RecoverySigner',p.recovery_identity('b'*40,123457,1))]:
   bad=copy.deepcopy(rows);bad[0]['verificationResult']['statement']['predicate'][field]=value
   with self.assertRaises(ValueError):p.validate_verified(bad,p.PROVENANCE,r,body)
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
  self.assertIn('predicate-type: '+p.PROVENANCE,text);self.assertNotIn('predicate-type: '+p.SLSA_PROVENANCE,text)
  self.assertIn('Attest signed same-artifact recovery statement',text)
  self.assertLess(text.index('Attest original image SBOM'),text.index('Complete exact immutable release'))
  self.assertNotIn('docker build',text);self.assertNotIn('docker push',text);self.assertNotIn('docker pull',text)
  self.assertEqual(len(owner.NAMES),35)
 def test_safe_log_diagnostic_never_exposes_signed_url_or_token(self):
  secret=b'gh: Resource not accessible by integration (HTTP 403) Authorization: Bearer TEST_TOKEN Location: https://storage.example/log?sig=TEST_SAS'
  result=subprocess.CompletedProcess([],1,b'{"secret":"DO_NOT_ECHO"}',secret)
  detail=p.safe_log_diagnostic('job-log',result,p.LOG_CAP);encoded=json.dumps(detail)
  self.assertEqual(detail['httpStatus'],403);self.assertTrue(detail['permissionDenied'])
  for value in ('TEST_TOKEN','TEST_SAS','DO_NOT_ECHO','Location','Authorization','https://'):self.assertNotIn(value,encoded)
  detail=p.safe_log_diagnostic('job-log',subprocess.CompletedProcess([],1,b'',b'HTTP 503 transient'),p.LOG_CAP);self.assertTrue(detail['serverError'])
 def test_official_archive_fallback_is_exact_and_bounded(self):
  original=(p.LOG_BYTES,p.LOG_SHA);body=b'Explicit unit fixture only: exact original tlog500 log bytes'
  p.LOG_BYTES,p.LOG_SHA=len(body),p.sha(body)
  def archive(name=p.ATTEMPT_ENTRY,payload=body):
   target=io.BytesIO()
   with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED)as z:z.writestr(name,payload)
   return target.getvalue()
  calls=[];diags=[]
  def runner(command,**kwargs):
   calls.append(command)
   if command[-1].endswith('/actions/jobs/'+str(p.JOB)+'/logs'):return subprocess.CompletedProcess(command,1,b'',b'gh: forbidden (HTTP 403) Location: https://download/?sig=NEVER_PRINT')
   self.assertTrue(command[-1].endswith('/actions/runs/'+str(p.RUN)+'/attempts/1/logs'))
   return subprocess.CompletedProcess(command,0,archive(),b'')
  try:
   self.assertEqual(p.fetch_original_log(runner,diags.append),body);self.assertEqual(len(calls),2);self.assertEqual(calls[0][2:6],['--method','GET','--header','Accept: application/vnd.github+json'])
   self.assertEqual(diags[0]['httpStatus'],403);self.assertTrue(diags[-1]['exactOriginalLogMatched']);self.assertNotIn('NEVER_PRINT',json.dumps(diags))
   for raw in (archive('wrong-job.txt'),archive(payload=body+b'changed'),b'not-a-zip'):
    with self.assertRaises(ValueError):p.log_from_attempt_archive(raw)
   with self.assertRaises(ValueError):p.log_from_attempt_archive(b'x'*(p.LOG_CAP+1))
   with self.assertRaises(ValueError):p.fetch_original_log(lambda *a,**k:subprocess.CompletedProcess([],1,b'',b'HTTP 500'),lambda d:None)
  finally:p.LOG_BYTES,p.LOG_SHA=original
 def test_real_collected_original_when_provided(self):
  if args.original_evidence is None:self.skipTest('Optional actual-byte reader not a CI fixture')
  root=args.original_evidence;p.validate_original(json.loads((root/'run-original.json').read_bytes()),json.loads((root/'jobs-original.json').read_bytes()),(root/'job-original.log').read_bytes(),json.loads((root/'artifact-original.json').read_bytes()))
  rows=owner.validate_archive((root/'original-publication-evidence.zip').read_bytes());self.assertEqual(owner.sha(rows['server.cdx.json']),owner.SBOM_SHA)
  self.assertNotIn('release-notes.md',rows)
  if args.official_attempt_archive is not None:
   log=p.log_from_attempt_archive(args.official_attempt_archive.read_bytes());self.assertEqual(log,(root/'job-original.log').read_bytes())
   self.assertEqual(len(log),764984)
if __name__=='__main__':unittest.main()
