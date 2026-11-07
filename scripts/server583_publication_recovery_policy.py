"""Exact Server583 original-builder / recovery-signer policy. No implicit I/O; fixed official-log retrieval uses an explicit runner callback."""
import hashlib,json,re
REPO='PastureStack/server'
TAG='v1.6.583'
SOURCE='6e6befedc7cd97dc3685ef7f6010b1fa2506bd77'
TREE='aa6227d081ad14c6237e6af062357ce1c22d034b'
RUN=42381092651
JOB=128428683822
ARTIFACT=13578150593
ARTIFACT_BYTES=6656789
ARTIFACT_SHA='e1a66835172702f891e52aa2df524b47516b599191b722af859287c0f8548a26'
DIGEST='sha256:e22ecd94bbc83c2d34f49aa7dde231301f42a26de9a89c929e8a11d886b6c78c'
IMAGE='ghcr.io/pasturestack/server'
ORIGINAL_WORKFLOW='.github/workflows/publish-current-server.yml'
RECOVERY_WORKFLOW='.github/workflows/complete-server583-publication.yml'
BUILDER='https://github.com/'+REPO+'/'+ORIGINAL_WORKFLOW+'@refs/heads/main'
SIGNER='https://github.com/'+REPO+'/'+RECOVERY_WORKFLOW+'@refs/heads/main'
BUILD_TYPE='https://actions.github.io/buildtypes/workflow/v1'
SLSA_PROVENANCE='https://slsa.dev/provenance/v1'
PROVENANCE='https://github.com/'+REPO+'#recovery-v1'
MAX_RECOVERY_PREDICATE_TYPE_BYTES=64  # Conservative local bound; not a GitHub limit claim.
PROVENANCE_MODEL='SIGNED_SAME_ARTIFACT_RECOVERY_STATEMENT'
SBOM='https://cyclonedx.org/bom'
PASSED=('Run source gates','Build exact release image once','Flatten and compare the release image for classic overlay2',
 'Verify the actual candidate JDK security runtime','Verify ordinary Brotli operations against the actual final image',
 'Start, restart, and export the candidate','Retain the independent browser runtime SBOM from the actual candidate',
 'Scan the final merged runtime and create SBOM','Publish semantic image')
FILES={'.github/workflows/complete-server583-publication.yml','scripts/complete-server583-publication.py',
 'scripts/server583_publication_recovery_policy.py','scripts/test-complete-server583-publication.py',
 'docs/operations/server583-publication-recovery.md'}
def need(ok,reason):
 if not ok:raise ValueError(reason)
need(len(PROVENANCE.encode('utf-8'))<=MAX_RECOVERY_PREDICATE_TYPE_BYTES,'Conservative local recovery predicate-type length bound required')

def sha(raw):return hashlib.sha256(raw).hexdigest()
def recovery_identity(source,run,attempt):
 need(type(source)is str and re.fullmatch('[0-9a-f]{40}',source)and source!=SOURCE,'Exact distinct recovery signer source required')
 need(type(run)is int and run>0 and run!=RUN and type(attempt)is int and attempt>0,'Actual separate recovery run and attempt required')
 return {'repository':REPO,'workflow':RECOVERY_WORKFLOW,'ref':'refs/heads/main','source':source,'run':run,'attempt':attempt,
         'invocation':'https://github.com/'+REPO+'/actions/runs/'+str(run)+'/attempts/'+str(attempt)}

LOG_BYTES=764984
LOG_SHA='a5d33e87a21b0868a9f8ed6a4106199fa8605680192b44dd626ed6990198ec87'
LOG_CAP=2*1024**2
ATTEMPT_ENTRY='0_publish.txt'

def safe_log_diagnostic(kind,result,cap):
 # Never return stderr/body/headers/Location. Redirect URLs may carry SAS secrets.
 stderr=result.stderr if type(result.stderr)is bytes else b''
 stdout=result.stdout if type(result.stdout)is bytes else b''
 scan=stderr[:65536].decode('utf-8','replace');lower=scan.lower()
 statuses=re.findall(r'\bHTTP\s*[:=]?\s*([1-5][0-9]{2})\b',scan,re.I)
 status=int(statuses[-1])if statuses else None
 return {'endpointKind':kind,'exitCode':int(result.returncode),'stdoutBytes':len(stdout),'stderrBytes':len(stderr),
  'httpStatus':status,'stdoutCapExceeded':len(stdout)>cap,
  'permissionDenied':any(x in lower for x in('resource not accessible by integration','must have admin rights','bad credentials','forbidden')),
  'redirectFailure':'redirect'in lower,'serverError':status is not None and status>=500,
  'transportFailure':any(x in lower for x in('tls handshake','connection reset','context deadline','unexpected eof'))}

def exact_original_log(raw):
 need(type(raw)is bytes and len(raw)==LOG_BYTES and len(raw)<=LOG_CAP and sha(raw)==LOG_SHA,'Exact official original job log bytes required')
 return raw

def log_from_attempt_archive(raw):
 import io,zipfile
 need(type(raw)is bytes and 0<len(raw)<=LOG_CAP,'Official attempt log archive keeps2MiB download cap')
 try:
  with zipfile.ZipFile(io.BytesIO(raw))as archive:
   entries=archive.infolist();names=[x.filename for x in entries]
   need(len(entries)<=128 and len(names)==len(set(names))and sum(x.file_size for x in entries)<=2*LOG_CAP,'Bounded unambiguous official attempt archive required')
   need(names.count(ATTEMPT_ENTRY)==1,'Exact sole publish-job aggregate entry required')
   entry=archive.getinfo(ATTEMPT_ENTRY);need(not entry.is_dir()and entry.file_size==LOG_BYTES,'Exact publish job log size required')
   return exact_original_log(archive.read(entry))
 except(zipfile.BadZipFile,RuntimeError,KeyError):raise ValueError('Invalid official original attempt log archive')from None

def fetch_original_log(runner,diagnostic=None):
 # Both routes are official read-only API endpoints for this fixed original run/job.
 routes=(('job-log','repos/'+REPO+'/actions/jobs/'+str(JOB)+'/logs'),
         ('run-attempt1-log-archive','repos/'+REPO+'/actions/runs/'+str(RUN)+'/attempts/1/logs'))
 for kind,endpoint in routes:
  try:result=runner(['gh','api','--method','GET','--header','Accept: application/vnd.github+json',endpoint],capture_output=True,timeout=90)
  except Exception as error:
   detail={'endpointKind':kind,'exitCode':None,'stdoutBytes':0,'stderrBytes':0,'httpStatus':None,
           'transportException':'timeout'if type(error).__name__=='TimeoutExpired'else 'transport','rawDetailSuppressed':True}
   if diagnostic is not None:diagnostic(detail)
   continue
  detail=safe_log_diagnostic(kind,result,LOG_CAP)
  if result.returncode==0 and len(result.stdout)<=LOG_CAP:
   try:log=exact_original_log(result.stdout)if kind=='job-log'else log_from_attempt_archive(result.stdout)
   except(ValueError,TypeError):detail['exactOriginalLogMatched']=False
   else:
    detail['exactOriginalLogMatched']=True
    if diagnostic is not None:diagnostic(detail)
    return log
  if diagnostic is not None:diagnostic(detail)
 need(False,'Both official original-log routes failed exact readback; see bounded safe diagnostics')

def validate_original(run,jobs,log,artifact):
 need((run['id'],run['head_sha'],run['run_attempt'],run['event'],run['path'],run['status'],run['conclusion'])==
      (RUN,SOURCE,1,'workflow_dispatch',ORIGINAL_WORKFLOW,'completed','failure'),'Exact original failed publisher required')
 need(len(jobs['jobs'])==jobs['total_count']==1,'One exact original publisher job required')
 job=jobs['jobs'][0]
 need((job['id'],job['run_id'],job['head_sha'],job['run_attempt'],job['name'],job['conclusion'])==(JOB,RUN,SOURCE,1,'publish','failure'),'Exact original job identity required')
 failed=[s for s in job['steps']if s['conclusion']=='failure'];need(len(failed)==1 and failed[0]['name']=='Attest image provenance','Only provenance transport failure is eligible')
 for name in PASSED:need(sum(s['name']==name and s['conclusion']=='success'for s in job['steps'])==1,'Original required build/security step must pass: '+name)
 need(all(s['conclusion']=='success'for s in job['steps']if s['number']<failed[0]['number']),'Every step preceding failed attestation must pass')
 for name in ('Attest image SBOM','Create immutable GitHub Release'):need(sum(s['name']==name and s['conclusion']=='skipped'for s in job['steps'])==1,'Original later step must remain skipped')
 need(sum(s['name']=='Clean run-owned resources'and s['conclusion']=='success'for s in job['steps'])==1,'Original run-owned cleanup must pass')
 need(b'InternalError: error creating tlog entry - (500) unexpected result from transparency log'in log,'Exact original tlog HTTP500 diagnosis required')
 need((artifact['id'],artifact['name'],artifact['size_in_bytes'],artifact['digest'],artifact['workflow_run']['id'],artifact['workflow_run']['head_sha'],artifact['expired'])==
      (ARTIFACT,'server-'+TAG+'-publication-'+str(RUN),ARTIFACT_BYTES,'sha256:'+ARTIFACT_SHA,RUN,SOURCE,False),'Exact original artifact identity required')
 return job

def predicate(job,recovery):
 push=next(s for s in job['steps']if s['name']=='Publish semantic image')
 # The nested SLSA-shaped record is reconstruction, never an original signature.
 original_slsa={'buildDefinition':{'buildType':BUILD_TYPE,
   'externalParameters':{'workflow':{'repository':'https://github.com/'+REPO,'path':ORIGINAL_WORKFLOW,'ref':'refs/heads/main'}},
   'resolvedDependencies':[{'uri':'git+https://github.com/'+REPO+'@refs/heads/main','digest':{'gitCommit':SOURCE}}]},
  'runDetails':{'builder':{'id':BUILDER},'metadata':{'invocationId':'https://github.com/'+REPO+'/actions/runs/'+str(RUN)+'/attempts/1',
   'startedOn':job['started_at'],'finishedOn':push['completed_at']}}}
 return {'schemaVersion':1,'originalNativeSlsaAvailable':False,
  'originalBuild':{'repository':REPO,'workflow':ORIGINAL_WORKFLOW,'ref':'refs/heads/main','source':SOURCE,'tree':TREE,'run':RUN,'attempt':1,
   'conclusion':'failure','failure':'attestation-transparency-log-http500','buildSecurityAndImagePublish':'success',
   'passedBuildSecurityPublishSteps':list(PASSED),'runOwnedCleanup':'success'},
  'originalBuildProvenance':{'predicateType':SLSA_PROVENANCE,'predicate':original_slsa,
   'evidenceStatus':'RECONSTRUCTED_FROM_ORIGINAL_OFFICIAL_RECORDS_NOT_ORIGINAL_SIGNED_PROVENANCE','originalSignatureAvailable':False},
  'originalArtifact':{'id':ARTIFACT,'uri':'https://github.com/'+REPO+'/actions/artifacts/'+str(ARTIFACT),'sha256':ARTIFACT_SHA,'bytes':ARTIFACT_BYTES,
   'originalJob':JOB,'originalJobLogSha256':LOG_SHA},
  'RecoverySigner':recovery,'image':{'name':IMAGE,'digest':DIGEST},'imageRebuilt':False,'imageRepushed':False,'scansReplayed':False}

def verify_command(digest,predicate_type,recovery):
 need(digest==DIGEST and predicate_type in(PROVENANCE,SBOM),'Exact subject and predicate type required')
 return validate_verify_argv(['gh','attestation','verify','oci://'+IMAGE+'@'+DIGEST,'--repo',REPO,
  '--signer-workflow',REPO+'/'+RECOVERY_WORKFLOW,'--signer-digest',recovery['source'],
  '--source-digest',recovery['source'],'--source-ref','refs/heads/main','--predicate-type',predicate_type,'--format','json'])

def validate_verify_argv(command):
 # GitHub CLI makes these identity-selector flags mutually exclusive.
 selectors=('--cert-identity','--cert-identity-regex','--signer-repo','--signer-workflow')
 need(sum(x in command for x in selectors)==1 and '--signer-workflow'in command,'Exactly the fixed signer-workflow selector required')
 need('--repo'in command and '--signer-digest'in command and '--source-digest'in command and '--source-ref'in command,'All exact repository/source signer bindings required')
 return command

def validate_verified(rows,predicate_type,recovery,expected):
 need(predicate_type in(PROVENANCE,SBOM),'Exact custom recovery or original SBOM type required; no standard SLSA substitution')
 need(type(rows)is list and rows,'Native cryptographic verification result required');matched=[]
 for row in rows:
  result=row.get('verificationResult',{});cert=result.get('signature',{}).get('certificate',{})
  good=(cert.get('issuer')=='https://token.actions.githubusercontent.com'and cert.get('subjectAlternativeName')==SIGNER
    and cert.get('buildSignerURI')==SIGNER and cert.get('buildSignerDigest')==recovery['source']
    and cert.get('sourceRepositoryURI')=='https://github.com/'+REPO and cert.get('sourceRepositoryDigest')==recovery['source']
    and cert.get('sourceRepositoryRef')=='refs/heads/main'and cert.get('buildConfigURI')==SIGNER
    and cert.get('buildConfigDigest')==recovery['source']and cert.get('runInvocationURI')==recovery['invocation']
    and cert.get('runnerEnvironment')=='github-hosted'and any(x.get('type')=='Tlog'for x in result.get('verifiedTimestamps',[])))
  statement=result.get('statement',{})
  good=good and statement.get('_type')=='https://in-toto.io/Statement/v1'and statement.get('predicateType')==predicate_type
  good=good and statement.get('subject')==[{'name':IMAGE,'digest':{'sha256':DIGEST[7:]}}]and statement.get('predicate')==expected
  if good:matched.append(row)
 need(matched,'Exact recovery-signer/original-builder pair and unchanged predicate required')
 return matched

def validate_completion_run(run,jobs,recovery):
 need((run['id'],run['head_sha'],run['run_attempt'],run['event'],run['path'],run['status'],run['conclusion'])==
      (recovery['run'],recovery['source'],recovery['attempt'],'workflow_dispatch',RECOVERY_WORKFLOW,'completed','success'),'Actual successful completion run required')
 need(jobs['total_count']==len(jobs['jobs'])==1 and jobs['jobs'][0]['conclusion']=='success','Successful completion job required')
 for name in ('Validate exact original build and prepare immutable inputs','Attest signed same-artifact recovery statement','Attest original image SBOM','Complete exact immutable release and verify native chains'):
  need(sum(s['name']==name and s['conclusion']=='success'for s in jobs['jobs'][0]['steps'])==1,'Required completion step must pass: '+name)

def validate_source(commit,comparison):
 need(commit['sha']==SOURCE and commit['tree']['sha']==TREE and commit['verification']['verified']is True and commit['verification']['reason']=='valid','Signed original exact tested tree required')
 need(comparison['base_commit']['sha']==comparison['merge_base_commit']['sha']==SOURCE and comparison['status']=='ahead','Recovery must descend from exact original source')
 changed={x['filename']for x in comparison['files']}
 need(changed==FILES and all(x['status']=='added'for x in comparison['files']),'Only fixed recovery workflow/script/policy/tests/docs additions allowed')
