"""Complete fixed original Server583 bytes after a transparency-log HTTP500.
No image build/pull/retag/push or scanner/runtime invocation exists here.
"""
import argparse,hashlib,importlib.util,json,os,re,shutil,subprocess,time,urllib.request,zipfile
from pathlib import Path
import server583_publication_recovery_policy as policy
from server583_publication_recovery_policy import need,sha
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'.server583-publication-completion'
NAMES=('SHA256SUMS', 'build.log', 'brotli-runtime.txt', 'candidate.log', 'candidate-smoke.txt', 'host-api-0.38.8.tar.gz', 'host-api-package-check.txt', 'image-inspect.txt', 'java-security-runtime.txt', 'mfa-policy-api-smoke.txt', 'registration-basic-api-smoke.txt', 'published.txt', 'push.log', 'release-notes.md', 'reverse-proxy-after-restart.txt', 'reverse-proxy-before-restart.txt', 'sbom-identity.txt', 'security-summary.txt', 'server.openvex.json', 'server.vendor-pending.json', 'ubuntu-backports-evidence.tar', 'server-security-scan-raw.json', 'server-security-scan.json', 'server-nested-payloads.json', 'server-vulnerabilities-raw.tsv', 'server-vulnerabilities-unresolved.tsv', 'server.cdx.json', 'vendor-pending-summary.txt', 'web-console-runtime.cdx.json', 'web-console-runtime.cdx.json.sha256', 'web-console-sbom-identity.txt', 'web-console-runtime-scan-raw.json', 'web-console-runtime-scan-effective.json', 'web-console-runtime-scan-coverage.json', 'web-console-runtime-vulnerabilities.tsv.gz')
SOURCE_FILES={'server/Dockerfile.web-compose-release':'709d84f50fad3be2286fb90d1a6c7dbfa9f51d92409314598beed0b013809b15',
 'docs/releases/server-1.6.583.md':'4d0ef44515d6aa6e422ed4ec73782e89413fc6c4110d300e07019d226fa0660b',
 'scripts/render-server-release-notes.py':'df54ad3163696bc491eb7739e33bcaea482a5de69159a0ed4ca7b89cce73195b',
 '.github/workflows/publish-current-server.yml':'855396b26d3f5abbb7648b83b4706025c0885d9edbd15d6914730d2c1e7c7c52'}
CAP=32*1024**2
FLOOR=10*1024**3+256*1024**2
SBOM_SHA='3b24a8ec35e11f01d37834979ea6ec2e8217bd3479121dbec223052efad15c86'

def command(*args,cap=8*1024**2,timeout=120):
 r=subprocess.run(list(map(str,args)),capture_output=True,timeout=timeout)
 need(r.returncode==0 and len(r.stdout)<=cap,'Bounded required command failed: '+str(args[:3]));return r.stdout

def api(path):return json.loads(command('gh','api','repos/'+policy.REPO+'/'+path))

def write(path,raw):
 path=Path(path);need(path.resolve().is_relative_to(WORK.resolve())and not path.is_symlink(),'Closed completion output required')
 if not isinstance(raw,bytes):raw=(json.dumps(raw,indent=2)+'\n').encode()
 need(sum(p.stat().st_size for p in WORK.rglob('*')if p.is_file())+len(raw)<=CAP and shutil.disk_usage(ROOT).free>=FLOOR+len(raw),'Original evidence 32MiB cap and10GiB reserve required')
 need(not path.exists(),'Preserve existing completion evidence');path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('xb')as f:f.write(raw)
 return {'path':str(path),'bytes':len(raw),'sha256':sha(raw)}

def context():
 need(os.environ.get('GITHUB_REPOSITORY')==policy.REPO and os.environ.get('GITHUB_REF')=='refs/heads/main'
  and os.environ.get('GITHUB_JOB')=='complete','Official fixed main completion job required')
 r=policy.recovery_identity(os.environ.get('GITHUB_SHA'),int(os.environ.get('GITHUB_RUN_ID','0')),int(os.environ.get('GITHUB_RUN_ATTEMPT','0')))
 need(os.environ.get('GITHUB_WORKFLOW_REF')==policy.REPO+'/'+policy.RECOVERY_WORKFLOW+'@refs/heads/main'
  and os.environ.get('GITHUB_WORKFLOW_SHA')==r['source'],'Actual non-reusable recovery signer source must be truthful')
 return r

def absent(path):
 r=subprocess.run(['gh','api','repos/'+policy.REPO+'/'+path],capture_output=True,timeout=60)
 need(r.returncode!=0,'Preserve existing semantic release or tag')
 try:body=json.loads(r.stdout)
 except(ValueError,TypeError):raise ValueError('Exact GitHub404 required; never infer absence from transport')from None
 need(str(body.get('status'))=='404','Exact GitHub404 required')

def registry():
 with urllib.request.urlopen('https://ghcr.io/token?service=ghcr.io&scope=repository:pasturestack/server:pull',timeout=30)as response:token_raw=response.read(65537)
 need(0<len(token_raw)<=65536,'Bounded anonymous OCI token required');token=json.loads(token_raw)['token']
 def get(path):
  req=urllib.request.Request('https://ghcr.io/v2/pasturestack/server/'+path,headers={'Authorization':'Bearer '+token,'Accept':'application/vnd.oci.image.manifest.v1+json, application/vnd.docker.distribution.manifest.v2+json'})
  with urllib.request.urlopen(req,timeout=30)as response:raw=response.read(2*1024**2+1)
  need(0<len(raw)<=2*1024**2,'Bounded OCI metadata only required');return raw
 raw=get('manifests/'+policy.TAG);need('sha256:'+sha(raw)==policy.DIGEST,'Existing semantic image must retain original digest')
 manifest=json.loads(raw);need(manifest['schemaVersion']==2 and len(manifest['layers'])==1,'Original flat OCI image required')
 config_raw=get('blobs/'+manifest['config']['digest']);need(len(config_raw)==manifest['config']['size']and 'sha256:'+sha(config_raw)==manifest['config']['digest'],'Exact OCI config link required')
 config=json.loads(config_raw);need(config['config']['Labels']['org.opencontainers.image.revision']==policy.SOURCE and config['config']['Labels']['org.opencontainers.image.version']==policy.TAG,'Original source image labels required')
 return {'imageDigest':policy.DIGEST,'configDigest':manifest['config']['digest'],'layerDigest':manifest['layers'][0]['digest']}

def collect(recovery):
 run=api('actions/runs/'+str(policy.RUN));jobs=api('actions/runs/'+str(policy.RUN)+'/jobs');artifact=api('actions/artifacts/'+str(policy.ARTIFACT))
 diagnostics=[]
 def diagnostic(row):diagnostics.append(row);print(json.dumps({'originalLogDownload':row},sort_keys=True))
 try:log=policy.fetch_original_log(subprocess.run,diagnostic)
 finally:
  phase='complete'if(WORK/'prepared.json').exists()else'prepare'
  write(WORK/('original-log-download-'+phase+'-diagnostics.json'),{'originalRun':policy.RUN,'originalJob':policy.JOB,'attempt':1,'safeDiagnostics':diagnostics,'rawStderrOrSignedLocationIncluded':False})
 job=policy.validate_original(run,jobs,log,artifact)
 original=api('git/commits/'+policy.SOURCE);signer=api('git/commits/'+recovery['source']);comparison=api('compare/'+policy.SOURCE+'...'+recovery['source'])
 policy.validate_source(original,comparison)
 need(signer['sha']==recovery['source']and signer['verification']['verified']is True and signer['verification']['reason']=='valid','Normal signed recovery source required')
 return run,jobs,log,artifact,job,original,signer,comparison

def validate_archive(raw):
 need(len(raw)==policy.ARTIFACT_BYTES and sha(raw)==policy.ARTIFACT_SHA,'Exact one original artifact ZIP required')
 import io
 with zipfile.ZipFile(io.BytesIO(raw))as bundle:
  entries=bundle.infolist();need(len(entries)<=150 and len({x.filename for x in entries})==len(entries)and sum(x.file_size for x in entries)<=64*1024**2,'Bounded unambiguous original evidence required')
  source_names=set(NAMES[1:]) - {'release-notes.md','web-console-runtime-vulnerabilities.tsv.gz'}|{'web-console-runtime-vulnerabilities.tsv'}
  need(source_names<=set(bundle.namelist()),'All original fixed evidence inputs required')
  rows={name:bundle.read(name)for name in source_names}
 need(sha(rows['server.cdx.json'])==SBOM_SHA,'Unchanged original image SBOM required')
 text=rows['published.txt'].decode();need('source='+policy.SOURCE in text and 'digest='+policy.DIGEST in text and 'release='+policy.TAG in text,'Original published evidence must bind exact source/digest')
 need(b'critical_high=0 fixed_available=0 secrets=0'in rows['security-summary.txt'],'Original scan security gate must remain passed')
 bom=json.loads(rows['server.cdx.json']);component=bom['metadata']['component']
 need(bom['bomFormat']=='CycloneDX'and component['name']==policy.IMAGE and component['version']==policy.TAG
  and component['hashes']==[{'alg':'SHA-256','content':policy.DIGEST[7:]}]
  and {'name':'org.opencontainers.image.revision','value':policy.SOURCE}in component['properties'],'Original SBOM subject/source identity required')
 return rows

def prepare():
 recovery=context();need(not WORK.exists(),'Fresh completion workspace required; preserve prior attempt');WORK.mkdir()
 need(shutil.disk_usage(ROOT).free>=FLOOR+CAP,'Reserve all bounded completion writes before download')
 run,jobs,log,artifact,job,original,signer,comparison=collect(recovery)
 absent('releases/tags/'+policy.TAG);absent('git/ref/tags/'+policy.TAG);image=registry()
 raw=command('gh','api','repos/'+policy.REPO+'/actions/artifacts/'+str(policy.ARTIFACT)+'/zip',cap=8*1024**2)
 rows=validate_archive(raw);write(WORK/'original-publication.zip',raw)
 for name,doc in [('original-run.json',run),('original-jobs.json',jobs),('original-artifact.json',artifact),('original-source.json',original),('recovery-source.json',signer),('source-comparison.json',comparison)]:write(WORK/name,doc)
 write(WORK/'original-job.log',log)
 for name,raw in rows.items():write(WORK/'original-evidence'/name,raw)
 originals={}
 for path,digest in SOURCE_FILES.items():
  raw=command('gh','api','--header','Accept: application/vnd.github.raw+json','repos/'+policy.REPO+'/contents/'+path+'?ref='+policy.SOURCE)
  need(sha(raw)==digest and(ROOT/path).read_bytes()==raw,'Exact original image source/renderer/note/publisher inputs required');originals[path]=raw
 renderer=ROOT/'scripts/render-server-release-notes.py';spec=importlib.util.spec_from_file_location('unchanged_server_note_renderer',renderer);notes=importlib.util.module_from_spec(spec);spec.loader.exec_module(notes)
 body=notes.render(originals['docs/releases/server-1.6.583.md'].decode(),policy.TAG,policy.DIGEST,policy.SOURCE)
 body+='\n\nPublication completed from the same original image; no rebuild or image repush.\nOriginal build run (failed only during transparency-log attestation): https://github.com/'+policy.REPO+'/actions/runs/'+str(policy.RUN)+'\nRecovery signer/run: '+recovery['invocation']+'\nRecovery workflow source: `'+recovery['source']+'`. Original image build source remains `'+policy.SOURCE+'`.\nOriginal artifact SHA-256: `'+policy.ARTIFACT_SHA+'`.\n'
 write(WORK/'original-evidence/release-notes.md',body.encode())
 host=set(re.findall(rb'^ARG HOST_API_ARCHIVE_SHA256=([0-9a-f]{64})$',originals['server/Dockerfile.web-compose-release'],re.M));need(len(host)==1 and sha(rows['host-api-0.38.8.tar.gz']).encode()in host,'Original immutable Host API archive bytes required')
 compressed=command('gzip','-n','-c',WORK/'original-evidence/web-console-runtime-vulnerabilities.tsv');write(WORK/'original-evidence/web-console-runtime-vulnerabilities.tsv.gz',compressed)
 sums=''.join(sha((WORK/'original-evidence'/n).read_bytes())+'  '+n+'\n'for n in NAMES[1:]);write(WORK/'original-evidence/SHA256SUMS',sums.encode())
 need(len(NAMES)==35 and all((WORK/'original-evidence'/n).stat().st_size>0 for n in NAMES),'Complete exact35 publication assets required')
 write(WORK/'provenance-predicate.json',policy.predicate(job,recovery))
 planned={n:{'sha256':sha((WORK/'original-evidence'/n).read_bytes()),'bytes':(WORK/'original-evidence'/n).stat().st_size}for n in NAMES}
 write(WORK/'prepared.json',{'schema':'server583-original-artifact-recovery-prepared-v1','originalConclusion':'failure','recovery':recovery,'image':image,'assets':planned,'originalArtifactSha256':policy.ARTIFACT_SHA,'predicateSha256':sha((WORK/'provenance-predicate.json').read_bytes()),'imageBuilds':0,'imagePushes':0,'scansReplayed':0})
 print('Prepared exact original bytes and truthful recovery predicate; no image mutation')

def release_crypto(proof,assets,release_id,tag_sha):
 statement=proof['verificationResult']['statement'];predicate=statement['predicate']
 need(statement['_type']=='https://in-toto.io/Statement/v1'and statement['predicateType']=='https://in-toto.io/attestation/release/v0.2'
  and(predicate['repository'],predicate['tag'],predicate['databaseId'])==(policy.REPO,policy.TAG,str(release_id)),'Native immutable release crypto identity required')
 need(len(statement['subject'])==36 and {s['name']:s['digest']['sha256']for s in statement['subject']if'name'in s}=={a['name']:a['digest'][7:]for a in assets}
  and[s for s in statement['subject']if'uri'in s]==[{'uri':'pkg:github/'+policy.REPO+'@'+policy.TAG,'digest':{'sha1':tag_sha}}],'All35 exact assets and tag must be native cryptographic subjects')

def anonymous_assets(assets):
 rows=[]
 for asset in assets:
  need(0<asset['size']<=8*1024**2,'Fixed original public asset bound required')
  request=urllib.request.Request(asset['browser_download_url'],headers={'User-Agent':'PastureStack-exact-original-publication-verifier'})
  with urllib.request.urlopen(request,timeout=60)as response:raw=response.read(asset['size']+1)
  need(len(raw)==asset['size']and 'sha256:'+sha(raw)==asset['digest'],'Anonymous original public asset bytes required')
  rows.append({'name':asset['name'],'sha256':sha(raw),'bytes':len(raw),'anonymous':True,'status':'PASS'})
 need(len(rows)==35,'All35 anonymous assets required');return rows

def complete():
 recovery=context();prepared=json.loads((WORK/'prepared.json').read_bytes());need(prepared['recovery']==recovery,'Same actual recovery signer/run required')
 _,_,_,_,job,_,_,_=collect(recovery);need(registry()==prepared['image'],'Preserve existing exact semantic image and config')
 expected=policy.predicate(job,recovery);need(sha((WORK/'provenance-predicate.json').read_bytes())==prepared['predicateSha256']and json.loads((WORK/'provenance-predicate.json').read_bytes())==expected,'Prepared original-builder predicate must remain exact')
 for kind,name,body in [(policy.PROVENANCE,'oci-provenance.json',expected),(policy.SBOM,'oci-sbom.json',json.loads((WORK/'original-evidence/server.cdx.json').read_bytes()))]:
  raw=command(*policy.verify_command(policy.DIGEST,kind,recovery));policy.validate_verified(json.loads(raw),kind,recovery,body);write(WORK/name,raw)
 for n,row in prepared['assets'].items():p=WORK/'original-evidence'/n;need(p.stat().st_size==row['bytes']and sha(p.read_bytes())==row['sha256'],'Prepared release asset bytes changed')
 absent('releases/tags/'+policy.TAG);absent('git/ref/tags/'+policy.TAG)
 command('gh','release','create',policy.TAG,'--repo',policy.REPO,'--target',policy.SOURCE,'--title','PastureStack Server '+policy.TAG,'--notes-file',WORK/'original-evidence/release-notes.md',*[str(WORK/'original-evidence'/n)for n in NAMES],timeout=180)
 release=api('releases/tags/'+policy.TAG);actual={a['name']:{'sha256':a['digest'][7:],'bytes':a['size']}for a in release['assets']}
 need(release['immutable']is True and not release['draft']and not release['prerelease']and len(release['assets'])==35 and actual==prepared['assets'],'Exact35 immutable release assets required')
 ref=api('git/ref/tags/'+policy.TAG)['object'];tag_sha=ref['sha']
 target=api('git/tags/'+ref['sha'])['object']if ref['type']=='tag'else ref
 need(target['type']=='commit'and target['sha']==policy.SOURCE,'Release tag must retain original build source, never recovery commit')
 raw=command('gh','release','verify',policy.TAG,'--repo',policy.REPO,'--format','json');proof=json.loads(raw);release_crypto(proof,release['assets'],release['id'],tag_sha);write(WORK/'native-release-attestation.json',raw)
 anonymous=anonymous_assets(release['assets'])
 need(registry()==prepared['image'],'No semantic image overwrite during completion')
 report={'status':'PASS_EXACT_SERVER583_SAME_ARTIFACT_PUBLICATION_COMPLETION','originalRun':policy.RUN,'originalSource':policy.SOURCE,'originalTree':policy.TREE,'originalConclusion':'failure','originalFailure':'attestation-transparency-log-http500','originalArtifactId':policy.ARTIFACT,'originalArtifactSha256':policy.ARTIFACT_SHA,'imageDigest':policy.DIGEST,'recovery':recovery,'releaseId':release['id'],'assetCount':35,'cryptoSubjectCount':36,'assets':actual,'anonymousAssets':anonymous,'anonymousAssetCount':35,'imageBuilds':0,'imagePushes':0,'scansReplayed':0,'nativeAcceptance':'PENDING','fullFrontendPass':False}
 write(WORK/'publication-completion.json',report);print('PASS: original583 artifact completed; original run remains failure; native pending')

def main():
 p=argparse.ArgumentParser();p.add_argument('phase',choices=['prepare','complete']);a=p.parse_args();prepare()if a.phase=='prepare'else complete()
if __name__=='__main__':main()
