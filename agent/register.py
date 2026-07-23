#!/usr/bin/env python3
import base64
import json
import os
import sys
import time
from urllib import parse, request


def fail(message):
    print("echo {}; exit 1".format(message))
    sys.exit(1)


def api_url(path):
    base = os.environ.get("CATTLE_URL", "").rstrip("/")
    if not base:
        fail("Missing CATTLE_URL")
    return "{}/{}".format(base, path.lstrip("/"))


def auth_header():
    access = os.environ.get("CATTLE_REGISTRATION_ACCESS_KEY")
    secret = os.environ.get("CATTLE_REGISTRATION_SECRET_KEY")
    if not access or not secret:
        fail("Missing CATTLE_REGISTRATION_ACCESS_KEY or CATTLE_REGISTRATION_SECRET_KEY")
    token = "{}:{}".format(access, secret).encode("utf-8")
    return "Basic {}".format(base64.b64encode(token).decode("ascii"))


def http_json(method, url, body=None):
    data = None
    headers = {
        "Authorization": auth_header(),
        "Accept": "application/json",
    }
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"

    req = request.Request(url, data=data, headers=headers, method=method)
    try:
        with request.urlopen(req, timeout=60) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as exc:
        fail("PastureStack registration API request failed: {}".format(exc))


def collection_data(resource):
    data = resource.get("data", [])
    return data if isinstance(data, list) else []


def wait_success(resource, timeout=300):
    deadline = time.time() + timeout
    current = resource
    while time.time() < deadline:
        state = current.get("state")
        transitioning = current.get("transitioning")
        if state == "active" and transitioning in (None, "no"):
            return current
        if transitioning == "error":
            fail("Registration failed: {}".format(current.get("transitioningMessage", "unknown error")))
        self_url = current.get("links", {}).get("self")
        if not self_url:
            return current
        time.sleep(2)
        current = http_json("GET", self_url)
    fail("Timed out waiting for PastureStack registration")


key = sys.argv[1]
query = parse.urlencode({"key": key})
rs = collection_data(http_json("GET", api_url("/register?{}".format(query))))

if len(rs) > 0:
    r = wait_success(rs[0])
    r = collection_data(http_json("GET", api_url("/register?{}".format(query))))[0]
else:
    r = http_json("POST", api_url("/register"), {"key": key})
    r = wait_success(r)
    r = collection_data(http_json("GET", api_url("/register?{}".format(query))))[0]

fields = r.get("data", {}).get("fields", {})
access_key = r.get("accessKey") or fields.get("accessKey")
secret_key = r.get("secretKey") or fields.get("secretKey")
if not access_key or not secret_key:
    fail("PastureStack registration response did not include agent credentials")

print("export CATTLE_ACCESS_KEY={}".format(access_key))
print("export CATTLE_SECRET_KEY={}".format(secret_key))
