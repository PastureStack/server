#!/usr/bin/env python3
"""Authenticated API Key schema proof on a fresh disposable loopback Server only.

Creates one disposable local administrator. Never run on an existing database.
No password, bearer token, request body or response body is printed or saved.
"""
import argparse
import http.client
import json
import secrets


AUDIT_FIELDS = ('keyId', 'decision', 'outcome', 'httpStatus', 'requestId', 'actor',
                'targetType', 'targetId', 'operation', 'policyRevision', 'reason',
                'phase', 'preview', 'eventId', 'hostUuid', 'failureCode')


def validate_schema(name, schema):
    fields = schema['resourceFields']
    if name in ('apikey', 'apikeyrestricted'):
        assert fields['apiKeyPolicy']['type'] == 'map[json]', name + '-policy-type'
        assert fields['apiKeyPolicy']['create'] and fields['apiKeyPolicy']['update'], name + '-policy-write'
        assert fields['apiKeyPolicyRevision']['update'], name + '-policy-revision-cas'
        assert fields['securityConfirmation']['type'] == 'password', name + '-confirmation-secret-type'
    elif name == 'apikeypolicypreview':
        assert schema['collectionMethods'] == ['POST'], name + '-post-only'
        assert not schema['resourceMethods'], name + '-no-resource-mutation'
        for field in ('apiKeyId', 'apiKeyPolicy', 'apiKeyPolicyRevision', 'purpose',
                      'requestDigest', 'confirmationRequired'):
            assert field in fields, name + '-missing-' + field
        for field in ('purpose', 'requestDigest', 'confirmationRequired'):
            assert not fields[field].get('create') and not fields[field].get('update'), name + '-server-derived-' + field
    elif name == 'auditlog':
        for field in AUDIT_FIELDS:
            assert field in fields, name + '-missing-' + field
            assert not fields[field].get('create') and not fields[field].get('update'), name + '-readonly-' + field
    else:
        raise AssertionError('unexpected-schema')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', required=True, type=int)
    parser.add_argument('--disposable', action='store_true', required=True)
    args = parser.parse_args()
    assert 1 <= args.port <= 65535
    token = None

    def call(method, path, body=None, anonymous=False, expected=(200, 201, 202)):
        assert path.startswith(('/v1/', '/v1-auth/', '/v2-beta/'))
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
        if token and not anonymous:
            headers['Authorization'] = 'Bearer ' + token
        connection = http.client.HTTPConnection('127.0.0.1', args.port, timeout=20)
        try:
            connection.request(method, path, body=None if body is None else json.dumps(body), headers=headers)
            response = connection.getresponse()
            status, content = response.status, response.read()
        finally:
            connection.close()
        assert status in expected, method + ' ' + path + ': HTTP ' + str(status)
        return json.loads(content) if content else {}

    assert call('GET', '/v1-auth/config').get('enabled') is False, 'refusing-initialized-auth'
    assert not any(a.get('kind') == 'user' for a in call('GET', '/v2-beta/accounts')['data']), 'refusing-existing-users'
    assert not call('GET', '/v2-beta/hosts')['data'], 'refusing-existing-hosts'
    user, password = 'key-schema-smoke-' + secrets.token_hex(4), 'Qa!9-' + secrets.token_urlsafe(24)
    local = {'username': user, 'password': password, 'name': 'Disposable Key Schema QA',
             'accessMode': 'unrestricted', 'enabled': False}
    call('POST', '/v1/localauthconfigs', local)
    token = call('POST', '/v1/token', {'code': user + ':' + password, 'authProvider': 'localAuthConfig'})['jwt']
    local['enabled'] = True
    call('POST', '/v1/localauthconfigs', local)
    call('GET', '/v2-beta/accounts', anonymous=True, expected=(401,))
    assert call('GET', '/v2-beta/accounts').get('type') == 'collection', 'authenticated-administrator-required'
    print('PASS actual-authenticated-administrator-anonymous-denied', flush=True)
    for version in ('v1', 'v2-beta'):
        for name in ('apikey', 'apikeyrestricted', 'apikeypolicypreview', 'auditlog'):
            validate_schema(name, call('GET', '/' + version + '/schemas/' + name))
            print('PASS authenticated-' + version + '-' + name + '-schema', flush=True)
    print('API_KEY_SCHEMA_SMOKE_OK auth=local-administrator versions=v1,v2-beta schemas=8 secret_output=none', flush=True)


if __name__ == '__main__':
    main()
