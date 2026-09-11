#!/usr/bin/env python3
"""MFA contract smoke: ONLY a fresh, disposable Server on a loopback port.

Creates disposable local accounts and MFA configuration. Never run against an
existing installation. The caller owns removal of the test container/volumes.
No passwords, tokens, seeds, recovery codes, or response bodies are logged.
"""
import argparse
import base64
import hashlib
import hmac
import json
import secrets
import struct
import time
import urllib.error
import urllib.request


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', required=True, type=int)
    parser.add_argument('--disposable', action='store_true', required=True)
    parser.add_argument('--api-version', choices=('v1', 'v2-beta'), default='v2-beta')
    args = parser.parse_args()
    assert 1 <= args.port <= 65535
    # Fixed loopback authority: callers cannot supply a remote URL, and the
    # local fixture cannot redirect this privileged smoke to another server.
    base = 'http://127.0.0.1:' + str(args.port)

    class NoRedirect(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, newurl):
            return None

    http = urllib.request.build_opener(urllib.request.ProxyHandler({}), NoRedirect())
    api = '/' + args.api_version
    token = None
    passed = []

    def call(method, path, data=None, expected=(200, 201, 202), bearer=None):
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
        auth = token if bearer is None else bearer
        if auth:
            headers['Authorization'] = 'Bearer ' + auth
        req = urllib.request.Request(base + path, method=method, headers=headers,
                                     data=None if data is None else json.dumps(data).encode())
        try:
            with http.open(req, timeout=20) as response:
                status, content = response.status, response.read()
        except urllib.error.HTTPError as error:
            status, content = error.code, error.read()
        assert status in expected, f'{method} {path}: unexpected HTTP {status}'
        return json.loads(content)

    def check(name, condition):
        assert condition, name
        passed.append(name)
        print('PASS ' + name, flush=True)

    config = call('GET', '/v1-auth/config')
    assert config.get('enabled') is False, 'refusing an initialized authentication system'
    accounts = call('GET', api + '/accounts')['data']
    assert not any(a.get('kind') == 'user' for a in accounts), 'refusing existing user accounts'
    assert not call('GET', api + '/hosts')['data'], 'refusing an installation with hosts'
    username = 'mfa-smoke-' + secrets.token_hex(4)
    password = 'Qa!9-' + secrets.token_urlsafe(24)
    local = {'username': username, 'password': password, 'name': 'Disposable MFA QA',
             'accessMode': 'unrestricted', 'enabled': False}
    call('POST', '/v1/localauthconfigs', local)
    login = call('POST', '/v1/token', {'code': username + ':' + password, 'authProvider': 'localAuthConfig'})
    token = login['jwt']
    local['enabled'] = True
    call('POST', '/v1/localauthconfigs', local)
    check('authenticated-administrator', call('GET', api + '/accounts').get('type') == 'collection')

    schema = call('GET', api + '/schemas/mfasettings')
    fields = schema['resourceFields']
    check('singleton-get-put', schema['collectionMethods'] == ['GET'] and set(schema['resourceMethods']) == {'GET', 'PUT'})
    check('all-37-policy-fields', len(fields) == 37 and not any(f['create'] for f in fields.values()))
    call('POST', api + '/mfaSettings', {}, expected=(405,))
    call('DELETE', api + '/mfaSettings/global', expected=(405,))
    check('singleton-create-and-delete-rejected', True)
    policy = {'origin': 'https://mfa.example.test', 'relyingPartyId': 'mfa.example.test',
              'maximumFailedAttempts': 12, 'lockoutSeconds': 120, 'securityConfirmationTtlSeconds': 60,
              'federatedMfaMode': 'trustedClaims', 'trustedAuthenticationMethods': 'mfa,otp',
              'trustedAuthenticationContexts': 'urn:example:aal2', 'maximumFederatedAuthenticationAgeSeconds': 180,
              'passkeyCounterPolicy': 'strict', 'securityEmailLocale': 'en-us'}
    for key in policy:
        assert fields[key]['update'], key + ' must be updateable'
    path = api + '/mfaSettings/global'

    def no_echo(resource):
        assert not {'smtpPassword', 'smtpClearPassword', 'securityConfirmation'} & set(resource), 'secret input echoed'

    saved = call('PUT', path, dict(policy, smtpPassword='Disposable-SMTP!9', smtpEnabled=False))
    no_echo(saved)
    loaded = call('GET', path)
    no_echo(loaded)
    check('policy-readback', all(loaded.get(k) == v for k, v in policy.items()))
    check('smtp-password-set-without-echo', loaded['smtpPasswordConfigured'])
    call('PUT', path, {'issuer': 'Disposable QA'})
    check('omitted-smtp-password-preserved', call('GET', path)['smtpPasswordConfigured'])
    call('PUT', path, {'smtpPassword': ''})
    check('blank-smtp-password-preserved', call('GET', path)['smtpPasswordConfigured'])
    conflict = call('PUT', path, {'smtpPassword': 'not-empty', 'smtpClearPassword': True}, expected=(400,))
    check('conflicting-password-operation-rejected', conflict['code'] == 'ConflictingSmtpPasswordChange')
    call('PUT', path, {'smtpClearPassword': True})
    check('explicit-smtp-clear', not call('GET', path)['smtpPasswordConfigured'])
    before_status = call('GET', path)['localAdministratorRecoveryStatus']
    call('PUT', path, {'localAdministratorRecoveryStatus': 'client-forged', 'smtpPasswordConfigured': True})
    after_status = call('GET', path)
    check('status-fields-remain-read-only', after_status['localAdministratorRecoveryStatus'] == before_status
          and not after_status['smtpPasswordConfigured'])

    def operation(data, bearer=None, expected=(200, 201, 202)):
        return call('POST', api + '/mfaOperations', data, expected=expected, bearer=bearer)

    def enroll(bearer=None):
        start = operation({'operation': 'beginTotpEnrollment'}, bearer)
        seed = base64.b32decode(start['totpSecret'])
        digest = hmac.new(seed, struct.pack('>Q', int(time.time()) // 30), hashlib.sha1).digest()
        offset = digest[-1] & 15
        code = str((struct.unpack('>I', digest[offset:offset+4])[0] & 0x7fffffff) % 1000000).zfill(6)
        result = operation({'operation': 'confirmTotpEnrollment', 'challengeId': start['challengeId'],
                            'verificationCode': code, 'label': 'Disposable QA'}, bearer)
        assert result['recoveryCodes'], 'recovery codes absent'
        return result['recoveryCodes']

    recovery_codes = enroll()
    denied = call('PUT', path, {'issuer': 'Must not save'}, expected=(401,))
    check('policy-requires-step-up', denied['code'] == 'MfaReauthenticationRequired')

    def confirm(codes, bearer=None):
        challenge = operation({'operation': 'beginSecurityConfirmation'}, bearer)
        assert 'recoveryCode' in challenge['methods'] and 'totp' in challenge['methods']
        result = operation({'operation': 'confirmSecurityConfirmation', 'challengeId': challenge['challengeId'],
                            'method': 'recoveryCode', 'recoveryCode': codes.pop()}, bearer)
        return result['securityConfirmation']

    ticket = confirm(recovery_codes)
    updated = call('PUT', path, {'issuer': 'MFA confirmed', 'securityConfirmation': ticket})
    no_echo(updated)
    check('step-up-save-and-reload', call('GET', path)['issuer'] == 'MFA confirmed')
    denied = call('PUT', path, {'issuer': 'Replay must not save', 'securityConfirmation': ticket}, expected=(401,))
    check('ticket-replay-rejected', denied['code'] == 'MfaReauthenticationRequired')
    check('replay-did-not-write', call('GET', path)['issuer'] == 'MFA confirmed')
    pk = operation({'operation': 'beginPasskeyEnrollment', 'securityConfirmation': confirm(recovery_codes)})
    public_key = pk['publicKey']
    if isinstance(public_key, str):
        public_key = json.loads(public_key)
    check('passkey-registration-starts', bool(pk['challengeId']) and public_key['rp']['id'] == policy['relyingPartyId'])

    normal = call('POST', api + '/accounts', {'kind': 'user', 'name': 'Disposable regular user'})
    normal_name = username + '-user'
    cred = call('POST', api + '/passwords', {'accountId': normal['id'], 'publicValue': normal_name, 'secretValue': password})
    for _ in range(40):
        if call('GET', api + '/passwords/' + cred['id']).get('state') == 'active':
            break
        time.sleep(0.5)
    else:
        raise AssertionError('disposable credential did not activate')
    normal_login = call('POST', '/v1/token', {'code': normal_name + ':' + password, 'authProvider': 'localAuthConfig'}, bearer='')
    normal_token = normal_login['jwt']
    call('GET', path, expected=(403, 404), bearer=normal_token)
    call('PUT', path, {'issuer': 'User must not save'}, expected=(403, 404, 405), bearer=normal_token)
    check('ordinary-user-cannot-read-or-update-policy', call('GET', path)['issuer'] == 'MFA confirmed')
    user_schema = call('GET', api + '/schemas/mfaoperation', bearer=normal_token)['resourceFields']
    check('ordinary-user-step-up-schema', all(k in user_schema for k in
          ('method', 'recoveryCode', 'securityConfirmation', 'methods', 'webAuthnOptions')))
    user_codes = enroll(normal_token)
    check('ordinary-user-step-up-flow', bool(confirm(user_codes, normal_token)))
    final_policy = call('GET', path)
    check('partial-updates-preserve-advanced-policy', all(final_policy.get(k) == v for k, v in policy.items()))
    for version in ('v1', 'v2-beta'):
        hardware = call('GET', '/' + version + '/schemas/launchconfig')['resourceFields']
        check(version + '-hardware-contract-retained', all(k in hardware for k in
              ('runtime', 'shmSize', 'deviceRequests', 'cpuQuota', 'cpuPeriod', 'pidsLimit', 'tmpfs', 'sysctls', 'ulimits')))
    print(json.dumps({'result': 'MFA_POLICY_API_OK', 'api': args.api_version, 'checks': len(passed)}), flush=True)


if __name__ == '__main__':
    main()
