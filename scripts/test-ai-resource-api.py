#!/usr/bin/env python3
"""Real typed-resource protocol smoke, only on a disposable loopback Server.

Called from the existing fresh-install smoke with its in-memory administrator.
No Host, workload, volume, MFA weakening, external URL or secret output.
"""
import base64
import http.client
import json
import secrets
import time
from urllib.parse import urlsplit


def run(*, port, administrator_jwt, administrator_account_id, disposable):
    assert disposable and port not in (80, 443, 8080) and 1024 <= port <= 65535
    assert isinstance(administrator_jwt, str) and administrator_jwt and administrator_account_id
    prefix = 'release-ai-' + secrets.token_hex(12)
    stack = key = plan = None
    public_origin = None
    checks = []

    def call(method, path, data=None, *, credential=None, human=False, expected=(200, 201, 202)):
        assert method in ('GET', 'POST', 'DELETE') and path.startswith('/v2-beta/')
        parsed = urlsplit(path)
        assert not parsed.scheme and not parsed.netloc and not parsed.fragment
        headers = {'Accept': 'application/json', 'Content-Type': 'application/json'}
        if credential:
            headers['Authorization'] = 'Basic ' + base64.b64encode(
                (credential['publicValue'] + ':' + credential['secretValue']).encode()).decode()
            headers['X-PastureStack-Key-Expected-Revision'] = str(credential['apiKeyPolicyRevision'])
        elif human:
            assert public_origin
            headers.update(Cookie='token=' + administrator_jwt, Origin=public_origin)
        else:
            headers['Authorization'] = 'Bearer ' + administrator_jwt
        # The authority comes from this disposable Server's own canonical link;
        # it is never followed as a network destination or supplied by a model.
        if public_origin:
            headers['Host'] = urlsplit(public_origin).netloc
        connection = http.client.HTTPConnection('127.0.0.1', port, timeout=20)
        try:
            connection.request(method, path, body=None if data is None else json.dumps(data).encode(), headers=headers)
            response = connection.getresponse(); raw = response.read(4 * 1024 * 1024 + 1)
            assert len(raw) <= 4 * 1024 * 1024
            value = json.loads(raw) if raw else {}
            assert response.status in expected, f'AI_RESOURCE_API_HTTP_{response.status}'
            return value
        finally:
            connection.close()

    def check(name, value):
        assert value, name
        checks.append(name)
        print('PASS ai-resource-' + name, flush=True)

    def settled(path, predicate, seconds=90):
        deadline = time.monotonic() + seconds
        while True:
            value = call('GET', path)
            if predicate(value): return value
            assert time.monotonic() < deadline, 'AI_RESOURCE_API_SETTLEMENT_TIMEOUT'
            time.sleep(.2)

    try:
        projects = call('GET', '/v2-beta/projects?limit=100')
        link = urlsplit(projects.get('links', {}).get('self', ''))
        assert link.scheme in ('http', 'https') and link.netloc and not link.username and not link.password
        public_origin = link.scheme + '://' + link.netloc
        available = [row for row in projects.get('data', []) if row.get('state') == 'active']
        assert len(available) == 1, 'FRESH_DISPOSABLE_DEFAULT_PROJECT_REQUIRED'
        project = available[0]; base = '/v2-beta/projects/' + project['id']
        pools = call('POST', base + '/aiResourceViews', {'resourceType': 'processPool'})
        rows = pools.get('data')
        check('real-process-pool-owner-projection', isinstance(rows, list) and bool(rows)
              and all(row.get('id', '').startswith('pool-') and row.get('name') for row in rows))
        detail = call('POST', base + '/aiResourceViews', {'resourceType': 'processPool', 'resourceId': rows[0]['id']})
        check('process-pool-opaque-detail', len(detail.get('data', [])) == 1 and detail['data'][0]['id'] == rows[0]['id'])
        unsupported = call('POST', base + '/aiResourceViews', {'resourceType': 'activeSetting'}, expected=(422,))
        check('unsupported-native-collection-is-not-an-auth-denial', unsupported.get('code') == 'ResourceViewInputInvalid')
        key = call('POST', '/v2-beta/apikeys', {'name': prefix + '-bridge',
            'apiKeyPolicy': {'purpose': 'ai-bridge', 'mode': 'custom', 'defaultEffect': 'deny',
                'rules': [{'id': 'one-disposable-project', 'effect': 'allow',
                    'scope': {'kind': 'project', 'resourceId': project['id']},
                    'operations': ['read', 'create', 'update', 'delete']}]}})
        assert key.get('name') == prefix + '-bridge' and key.get('id') and key.get('uuid')
        key_path = urlsplit(key['links']['self']).path
        assert key_path.startswith(('/v2-beta/apikeys/', '/v2-beta/apikeyrestricteds/'))
        fresh = settled(key_path, lambda row: row.get('state') == 'active', 30)
        key['apiKeyPolicyRevision'] = fresh['apiKeyPolicyRevision']
        plan = call('POST', base + '/aiResourceChangePlans', {'resourceType': 'stack', 'operation': 'create',
            'parameters': {'name': prefix + '-stack', 'description': 'Disposable protocol smoke; no Hosts or workloads'}}, credential=key)
        plan_path = base + '/aiResourceChangePlans/' + plan['id']
        check('scoped-key-preview-needs-human', plan.get('confirmationState') == 'pending')
        denied = call('POST', plan_path + '?action=confirm', {}, credential=key, expected=(403,))
        check('key-cannot-confirm-itself', denied.get('code') in ('AiBridgeRouteDenied', 'AiKeyConfirmationForbidden'))
        call('POST', plan_path + '?action=confirm', {}, human=True)
        accepted = call('POST', plan_path + '?action=apply', {}, credential=key)
        check('confirmed-create-accepted-once', accepted.get('status') == 'accepted')
        deadline = time.monotonic() + 90
        while True:
            result = call('GET', plan_path, credential=key)
            if result.get('status') == 'succeeded': break
            assert result.get('status') in ('accepted', 'running') and time.monotonic() < deadline, 'AI_RESOURCE_OPERATION_FAILED'
            time.sleep(.2)
        check('custom-key-can-read-decoded-created-target', result.get('verifiedResult') is True)
        stack_id = result.get('resourceId'); assert stack_id
        stack = call('GET', base + '/stacks/' + stack_id)
        check('created-stack-owner-and-name', stack.get('name') == prefix + '-stack' and stack.get('accountId') == project['id'])
        # No retry is sent to apply. An uncertain result is always a failure.
        check('no-workloads-created', not call('GET', base + '/services?stackId=' + stack_id).get('data'))
    finally:
        # Revoke the ephemeral credential first. Each cleanup must still run
        # when the other fails; either error keeps the smoke red and chained
        # to the original failure. The publisher also owns the disposable DB.
        try:
            if key:
                path = urlsplit(key['links']['self']).path; current = call('GET', path)
                assert all(current.get(field) == key.get(field) for field in ('id', 'uuid', 'name'))
                if current.get('state') == 'active': call('POST', path + '?action=deactivate', {})
                settled(path, lambda row: row.get('state') == 'inactive', 30)
                call('DELETE', path)
        finally:
            if stack:
                path = base + '/stacks/' + stack['id']; current = call('GET', path)
                assert all(current.get(field) == stack.get(field) for field in ('id', 'uuid', 'name', 'accountId'))
                assert not call('GET', base + '/services?stackId=' + stack['id']).get('data')
                call('DELETE', path)
    print('AI_RESOURCE_API_OK checks=' + str(len(checks)) + ' scoped_create_read=true process_pool=true human_cookie=true no_hosts=true', flush=True)
