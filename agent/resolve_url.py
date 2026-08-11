#!/usr/bin/env python3
import json
import sys
import time
from urllib import parse, request

from control_plane_url import ControlPlaneURLPolicy


def fail(message):
    print(message, file=sys.stderr)
    raise SystemExit(1)


class ControlPlaneClient:
    def __init__(self, base_url):
        self.policy = ControlPlaneURLPolicy(base_url)

    def http(self, method, url, body=None):
        checked_url = self.policy.validate(url)
        data = None
        headers = {"Accept": "application/json"}
        if body is not None:
            data = json.dumps(body).encode("utf-8")
            headers["Content-Type"] = "application/json"
        req = request.Request(
            checked_url, data=data, headers=headers, method=method
        )
        with self.policy.open(req, timeout=60) as resp:
            return resp.status, dict(resp.headers), resp.read().decode("utf-8")

    def http_json(self, method, url, body=None):
        status, headers, text = self.http(method, url, body)
        if status < 200 or status >= 300:
            fail("PastureStack API request failed with status {}".format(status))
        return json.loads(text), headers


def base_from_schemas(url):
    return url[:-8] if url.endswith("/schemas") else url.rstrip("/")


def collection_url(client, api_base, schema_name):
    schema, _ = client.http_json(
        "GET", "{}/schemas/{}".format(api_base.rstrip("/"), schema_name)
    )
    return schema.get("links", {}).get("collection")


def has_create(schema):
    methods = schema.get("collectionMethods") or []
    return "POST" in methods


def wait_success(client, resource, timeout=300):
    deadline = time.time() + timeout
    current = resource
    while time.time() < deadline:
        state = current.get("state")
        transitioning = current.get("transitioning")
        if state == "active" and transitioning in (None, "no"):
            return current
        if transitioning == "error":
            fail(
                "Registration token failed: {}".format(
                    current.get("transitioningMessage", "unknown error")
                )
            )
        self_url = current.get("links", {}).get("self")
        if not self_url:
            return current
        time.sleep(2)
        current, _ = client.http_json("GET", self_url)
    fail("Timed out waiting for registration token")


def active_registration_token(client, api_base):
    collection = collection_url(client, api_base, "registrationToken")
    if not collection:
        fail("Failed to find registrationToken collection")

    query = parse.urlencode({"state": "active"})
    tokens, _ = client.http_json("GET", "{}?{}".format(collection, query))
    data = tokens.get("data", [])
    if data:
        return data[0]

    token, _ = client.http_json("POST", collection, {})
    return wait_success(client, token)


def resolve_registration_url(url):
    client = ControlPlaneClient(url)
    initial_url = client.policy.validate(url)
    status, headers, text = client.http("GET", initial_url)
    if status == 200 and text.startswith("#!/bin/sh"):
        return initial_url

    schemas_url = (
        headers.get("X-API-Schemas") or headers.get("x-api-schemas") or initial_url
    )
    schemas_url = client.policy.validate(schemas_url)
    api_base = base_from_schemas(schemas_url)

    registration_schema, _ = client.http_json(
        "GET", "{}/schemas/registrationToken".format(api_base.rstrip("/"))
    )
    if not has_create(registration_schema):
        projects_url = collection_url(client, api_base, "project")
        if not projects_url:
            fail("Failed to find project collection")
        projects, _ = client.http_json(
            "GET",
            "{}?{}".format(
                projects_url, parse.urlencode({"uuid": "adminProject"})
            ),
        )
        data = projects.get("data", [])
        if not data:
            fail("Failed to find admin resource group")
        schemas_url = data[0].get("links", {}).get("schemas")
        if not schemas_url:
            fail("Failed to find admin resource group schemas")
        api_base = base_from_schemas(client.policy.validate(schemas_url))

    token = active_registration_token(client, api_base)
    registration_url = token.get("registrationUrl") or token.get("links", {}).get(
        "registrationUrl"
    )
    if not registration_url:
        fail("Registration token response did not include registrationUrl")
    return client.policy.validate(registration_url)


def main(argv):
    if len(argv) != 2:
        fail("Usage: resolve_url.py CONTROL_PLANE_URL")
    try:
        print(resolve_registration_url(argv[1]))
    except (ValueError, OSError, json.JSONDecodeError) as exc:
        fail("Failed to resolve the PastureStack registration URL: {}".format(exc))


if __name__ == "__main__":
    main(sys.argv)
