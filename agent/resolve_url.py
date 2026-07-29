#!/usr/bin/env python3
import json
import sys
import time
from urllib import parse, request


def fail(message):
    print(message)
    sys.exit(1)


def http(method, url, body=None):
    data = None
    headers = {"Accept": "application/json"}
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = request.Request(url, data=data, headers=headers, method=method)
    with request.urlopen(req, timeout=60) as resp:
        return resp.status, dict(resp.headers), resp.read().decode("utf-8")


def http_json(method, url, body=None):
    status, headers, text = http(method, url, body)
    if status < 200 or status >= 300:
        fail("PastureStack API request failed with status {}".format(status))
    return json.loads(text), headers


def base_from_schemas(url):
    return url[:-8] if url.endswith("/schemas") else url.rstrip("/")


def collection_url(api_base, schema_name):
    schema, _ = http_json("GET", "{}/schemas/{}".format(api_base.rstrip("/"), schema_name))
    return schema.get("links", {}).get("collection")


def has_create(schema):
    methods = schema.get("collectionMethods") or []
    return "POST" in methods


def wait_success(resource, timeout=300):
    deadline = time.time() + timeout
    current = resource
    while time.time() < deadline:
        state = current.get("state")
        transitioning = current.get("transitioning")
        if state == "active" and transitioning in (None, "no"):
            return current
        if transitioning == "error":
            fail("Registration token failed: {}".format(current.get("transitioningMessage", "unknown error")))
        self_url = current.get("links", {}).get("self")
        if not self_url:
            return current
        time.sleep(2)
        current, _ = http_json("GET", self_url)
    fail("Timed out waiting for registration token")


def active_registration_token(api_base):
    collection = collection_url(api_base, "registrationToken")
    if not collection:
        fail("Failed to find registrationToken collection")

    query = parse.urlencode({"state": "active"})
    tokens, _ = http_json("GET", "{}?{}".format(collection, query))
    data = tokens.get("data", [])
    if data:
        return data[0]

    token, _ = http_json("POST", collection, {})
    return wait_success(token)


url = sys.argv[1]
status, headers, text = http("GET", url)
if status == 200 and text.startswith("#!/bin/sh"):
    print(url)
    sys.exit(0)

schemas_url = headers.get("X-API-Schemas") or headers.get("x-api-schemas") or url
api_base = base_from_schemas(schemas_url)

registration_schema, _ = http_json("GET", "{}/schemas/registrationToken".format(api_base.rstrip("/")))
if not has_create(registration_schema):
    projects_url = collection_url(api_base, "project")
    if not projects_url:
        fail("Failed to find project collection")
    projects, _ = http_json("GET", "{}?{}".format(projects_url, parse.urlencode({"uuid": "adminProject"})))
    data = projects.get("data", [])
    if not data:
        fail("Failed to find admin resource group")
    schemas_url = data[0].get("links", {}).get("schemas")
    if not schemas_url:
        fail("Failed to find admin resource group schemas")
    api_base = base_from_schemas(schemas_url)

token = active_registration_token(api_base)
registration_url = token.get("registrationUrl") or token.get("links", {}).get("registrationUrl")
if not registration_url:
    fail("Registration token response did not include registrationUrl")
print(registration_url)
