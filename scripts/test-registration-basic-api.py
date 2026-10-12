#!/usr/bin/env python3
"""Focused native registration entry smoke sharing the disposable MFA bootstrap.

Call run() with its already-issued administrator session, before MFA enrollment.
No auth bootstrap, SQL, agent launch, redirects, secret files or response logs.
The publication workflow owns the candidate container and all three volumes.
"""
import base64
import hashlib
import http.client
import json
import re
import secrets
import time
from urllib.parse import urlsplit

PORT = 18082
ORIGIN = 'https://stack.example.test'
ORIGINS = frozenset((ORIGIN, 'http://127.0.0.1:18082'))
BOUND = 2 * 1024 * 1024


class SmokeFailure(RuntimeError):
    pass


def require(condition, code):
    if not condition:
        raise SmokeFailure('REGISTRATION_BASIC_API_' + code)


def native_path(link, expected):
    require(isinstance(link, str) and len(link) <= 8192, 'NATIVE_LINK')
    parsed = urlsplit(link)
    authority = parsed.scheme + '://' + parsed.netloc
    require((not parsed.scheme and not parsed.netloc or authority in ORIGINS)
            and not parsed.query and not parsed.fragment and '\\' not in link
            and '..' not in parsed.path and parsed.path == expected, 'OWNED_NATIVE_LINK')
    return parsed.path


def collection(schema, kind, path):
    require(schema.get('id') == kind and 'POST' in schema.get('collectionMethods', []), 'NATIVE_POST_SCHEMA')
    return native_path(schema.get('links', {}).get('collection'), path)


def ordinary_kind_creatable(field):
    if not isinstance(field, dict) or field.get('create') is not True:
        return False
    options = field.get('options')
    if options is None:
        return field.get('type') == 'string'
    return field.get('type') in ('string', 'enum') and isinstance(options, list) and 'user' in options


def private_absent(raw, value, private):
    require(not any(secret.encode() in raw for secret in private if secret), 'PRIVATE_RESPONSE')
    def walk(node):
        if isinstance(node, str):
            require(not any(secret in node for secret in private if secret), 'PRIVATE_RESPONSE')
        elif isinstance(node, dict):
            for key, item in node.items(): walk(key); walk(item)
        elif isinstance(node, list):
            for item in node: walk(item)
    walk(value)


class Client:
    def __init__(self, port):
        require(type(port) is int and port == PORT, 'DISPOSABLE_LOOPBACK_PORT')
        self.port, self.private, self.used_posts = port, [], set()
        self.post_paths = {'/v2-beta/accounts', '/v2-beta/apikeys', '/v2-beta/projects'}

    def request(self, method, path, data=None, auth=None, cookie=None):
        parsed = urlsplit(path)
        require(method in ('GET', 'POST') and path.startswith(('/v1/', '/v2-beta/'))
                and not parsed.scheme and not parsed.netloc and not parsed.query and not parsed.fragment
                and '..' not in path and '\\' not in path, 'OWNED_REQUEST')
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json',
                   'Host': urlsplit(ORIGIN).netloc, 'Origin': ORIGIN}
        if auth: headers['Authorization'] = auth
        if cookie: headers['Cookie'] = cookie
        connection = http.client.HTTPConnection('127.0.0.1', port=self.port, timeout=20)
        try:
            connection.request(method, path, headers=headers,
                               body=None if data is None else json.dumps(data).encode())
            response = connection.getresponse()
            raw = response.read(BOUND + 1); require(len(raw) <= BOUND, 'RESPONSE_BOUND')
            principal = (response.getheader('X-API-USER-ID'), response.getheader('X-API-ACCOUNT-ID'))
            return response.status, raw, principal
        finally:
            connection.close()

    def json(self, method, path, data=None, auth=None, cookie=None, expected=200):
        status, raw, principal = self.request(method, path, data, auth, cookie)
        require(status == expected, 'HTTP_STATUS_' + str(status) + '_EXPECTED_' + str(expected))
        value = json.loads(raw); require(isinstance(value, dict), 'JSON_OBJECT')
        return value, raw, principal

    def post(self, path, data, auth):
        require(path in self.post_paths and path not in self.used_posts, 'NATIVE_POST_ONCE')
        self.used_posts.add(path)  # A failed request is never retried as a POST.
        return self.json('POST', path, data, auth, expected=201)[0]

    def active(self, path, auth, project=False):
        require(not project or re.fullmatch(r'/v2-beta/projects/1a[1-9][0-9]*', path), 'PROJECT_ACTIVE_PATH')
        deadline = time.monotonic() + 60
        while True:
            status, raw, _ = self.request('GET', path, auth=auth)
            value = json.loads(raw); require(isinstance(value, dict), 'JSON_OBJECT')
            # The ordinary creator's native membership must become visible;
            # only this exact new-project Not Found can remain a waiting state.
            waiting = project and status == 404 and value.get('code') == 'Not Found'
            require(status == 200 or waiting, 'ACTIVE_HTTP_STATUS')
            if status == 200 and value.get('state') == 'active':
                require(not project or value.get('id') == path.rsplit('/', 1)[-1], 'PROJECT_ACTIVE_ID')
                return value
            require(time.monotonic() < deadline, 'NATIVE_ACTIVE_TIMEOUT')
            time.sleep(.2)


def run(*, port, administrator_jwt, administrator_account_id, disposable):
    require(disposable is True, 'DISPOSABLE_REQUIRED')
    require(isinstance(administrator_jwt, str) and len(administrator_jwt) >= 20
            and '\n' not in administrator_jwt and '\r' not in administrator_jwt, 'SHARED_ADMIN_SESSION')
    require(re.fullmatch(r'1a[1-9][0-9]*', administrator_account_id or ''), 'SHARED_ADMIN_ACCOUNT')
    client = Client(port)
    admin = 'Bearer ' + administrator_jwt
    client.private.extend((administrator_jwt, admin))
    try:
        schemas = {kind: client.json('GET', '/v2-beta/schemas/' + kind, auth=admin)[0]
                   for kind in ('account', 'apiKey', 'project')}
        account_path = collection(schemas['account'], 'account', '/v2-beta/accounts')
        key_path = collection(schemas['apiKey'], 'apiKey', '/v2-beta/apikeys')
        project_path = collection(schemas['project'], 'project', '/v2-beta/projects')
        kind_field = schemas['account'].get('resourceFields', {}).get('kind', {})
        require(ordinary_kind_creatable(kind_field)
                and schemas['apiKey']['resourceFields']['accountId'].get('create') is True, 'ORDINARY_USER_SCHEMA')
        name = 'registration-smoke-' + secrets.token_hex(8)
        actor = client.post(account_path, {'kind': 'user', 'name': name}, admin)
        actor_id = actor.get('id')
        require(re.fullmatch(r'1a[1-9][0-9]*', actor_id or '') and actor_id != administrator_account_id
                and actor.get('kind') == 'user' and actor.get('name') == name, 'ORDINARY_USER')
        actor = client.active(account_path + '/' + actor_id, admin)
        require(actor.get('kind') == 'user', 'ORDINARY_USER')
        # Missing policy is a current native legacy/full control, not an upgrade claim.
        key = client.post(key_path, {'type': 'apiKey', 'name': name + '-key', 'accountId': actor_id}, admin)
        require(key.get('accountId') == actor_id and isinstance(key.get('publicValue'), str)
                and isinstance(key.get('secretValue'), str) and len(key['secretValue']) >= 16, 'NATIVE_OWNER_KEY')
        basic = 'Basic ' + base64.b64encode((key['publicValue'] + ':' + key['secretValue']).encode()).decode()
        client.private.extend((key['publicValue'], key['secretValue'], basic))
        key_id = key.get('id'); require(re.fullmatch(r'1c[1-9][0-9]*', key_id or ''), 'KEY_ID')
        self_path = urlsplit(key.get('links', {}).get('self', '')).path
        require(self_path in (key_path + '/' + key_id, '/v2-beta/apikeyrestricteds/' + key_id), 'KEY_SELF')
        native_path(key['links']['self'], self_path)
        ready = client.active(self_path, admin)
        require(ready.get('accountId') == actor_id and type(ready.get('apiKeyPolicyRevision')) is int
                and ready['apiKeyPolicyRevision'] == 0, 'LEGACY_KEY_OWNER')
        own, raw, principal = client.json('GET', account_path + '/' + actor_id, auth=basic)
        private_absent(raw, own, client.private)
        require(own.get('kind') == 'user' and principal == (actor_id, actor_id), 'ORDINARY_BASIC_PRINCIPAL')
        project = client.post(project_path, {'name': name + '-project'}, basic)
        project_id = project.get('id'); require(re.fullmatch(r'1a[1-9][0-9]*', project_id or '')
                                               and project_id not in (actor_id, administrator_account_id)
                                               and project.get('kind') == 'project'
                                               and project.get('name') == name + '-project', 'NATIVE_PROJECT')
        client.active(project_path + '/' + project_id, basic, project=True)
        own, raw, principal = client.json('GET', '/v1/projects/' + project_id, auth=basic)
        private_absent(raw, own, client.private)
        require(own.get('id') == project_id and principal == (actor_id, actor_id), 'LEGACY_BASIC_CONTROL')
        prefix = '/v2-beta/projects/' + project_id
        schema = client.json('GET', prefix + '/schemas/registrationToken', auth=basic)[0]
        token_path = collection(schema, 'registrationToken', prefix + '/registrationtokens')
        client.post_paths.add(token_path)
        token = client.post(token_path, {'type': 'registrationToken'}, basic)
        token_id = token.get('id'); require(re.fullmatch(r'1c[1-9][0-9]*', token_id or ''), 'TOKEN_ID')
        token = client.active(token_path + '/' + token_id, basic)
        secret = token.get('token')
        require(token.get('accountId') == project_id and isinstance(secret, str)
                and len(secret.split(':')) == 3, 'NATIVE_REGISTRATION_TOKEN')
        url = token.get('registrationUrl'); require(isinstance(url, str), 'NATIVE_SCRIPT_URL')
        script = urlsplit(url).path
        require(script.startswith(prefix + '/scripts/') and len(script.rsplit('/', 1)[-1]) > 20, 'PROJECT_SCRIPT')
        native_path(url, script)
        registration = 'Basic ' + base64.b64encode(('registrationToken:' + secret).encode()).decode()
        wrong = secret[:-1] + ('A' if secret[-1] != 'A' else 'B')
        invalid = 'Basic ' + base64.b64encode(('registrationToken:' + wrong).encode()).decode()
        cookie = 'token=' + administrator_jwt
        client.private.extend((secret, url, script, registration, wrong, invalid, cookie))
        status, body, _ = client.request('GET', script)
        require(status == 200 and body.startswith(b'#!') and secret.encode() in body
                and b'registrationToken' in body, 'GENERATED_SCRIPT')
        script_hash = hashlib.sha256(body).hexdigest()
        value, raw, principal = client.json('GET', '/v1/register', auth=registration)
        private_absent(raw, value, client.private)
        require(value.get('type') == 'collection' and value.get('resourceType') == 'register'
                and isinstance(value.get('data'), list) and principal == (project_id, project_id), 'NATIVE_REGISTER_GET')
        value, raw, principal = client.json('GET', '/v1/schemas/register', auth=registration)
        private_absent(raw, value, client.private)
        require(value.get('id') == 'register' and 'GET' in value.get('collectionMethods', [])
                and principal == (project_id, project_id), 'RESTRICTED_REGISTER_SCHEMA')
        value, raw, principal = client.json('GET', '/v1/accounts', auth=registration, expected=404)
        private_absent(raw, value, client.private)
        require(value.get('code') == 'Not Found' and principal == (project_id, project_id), 'REGISTRATION_CANNOT_ACCOUNTS')
        value, raw, principal = client.json('GET', '/v2-beta/projects/' + project_id, cookie=cookie)
        private_absent(raw, value, client.private)
        require(value.get('id') == project_id and principal == (administrator_account_id, administrator_account_id), 'VALID_COOKIE_CONTROL')
        value, raw, principal = client.json('GET', '/v1/register', auth=invalid, cookie=cookie, expected=401)
        private_absent(raw, value, client.private)
        require(value.get('code') == 'Unauthorized' and principal == (None, None), 'INVALID_TOKEN_NO_COOKIE_FALLTHROUGH')
        print('REGISTRATION_BASIC_API_OK checks=7 ordinary_user=true entry_only=true node_active_verified=false script_sha256=' + script_hash,
              flush=True)
        return {'checks': 7, 'ordinaryUser': True, 'nodeActiveVerified': False, 'scriptSha256': script_hash}
    except SmokeFailure:
        raise
    except Exception:
        raise SmokeFailure('REGISTRATION_BASIC_API_FAILURE') from None
    finally:
        client.private.clear()


if __name__ == '__main__':
    print('PLAN_ONLY: shared disposable test-mfa-policy-api.py --registration-basic bootstrap required; no runtime executed.')
