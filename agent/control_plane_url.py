#!/usr/bin/env python3
"""Same-origin URL policy for node-agent control-plane requests."""

from urllib import parse, request


class ControlPlaneURLPolicy:
    def __init__(self, base_url):
        self.base_url = self._validate_absolute(base_url)
        self.origin = self._origin(self.base_url)
        self._opener = request.build_opener(self._redirect_handler())

    @staticmethod
    def _origin(url):
        parts = parse.urlsplit(url)
        try:
            port = parts.port
        except ValueError as exc:
            raise ValueError("control-plane URL has an invalid port") from exc
        if port is None:
            port = 443 if parts.scheme.lower() == "https" else 80
        return parts.scheme.lower(), parts.hostname.lower(), port

    @staticmethod
    def _validate_absolute(url):
        if not isinstance(url, str) or len(url) < 8 or len(url) > 16 * 1024:
            raise ValueError("control-plane URL is invalid")
        parts = parse.urlsplit(url)
        if parts.scheme.lower() not in ("http", "https"):
            raise ValueError("control-plane URL must use HTTP or HTTPS")
        if not parts.hostname or parts.username is not None or parts.password is not None:
            raise ValueError("control-plane URL must contain a host without credentials")
        if parts.fragment:
            raise ValueError("control-plane URL must not contain a fragment")
        try:
            _ = parts.port
        except ValueError as exc:
            raise ValueError("control-plane URL has an invalid port") from exc
        return parse.urlunsplit(
            (parts.scheme.lower(), parts.netloc, parts.path or "/", parts.query, "")
        )

    def validate(self, candidate):
        if not isinstance(candidate, str) or not candidate:
            raise ValueError("control-plane response contained an invalid URL")
        resolved = parse.urljoin(self.base_url, candidate)
        checked = self._validate_absolute(resolved)
        if self._origin(checked) != self.origin:
            raise ValueError("control-plane response attempted a cross-origin request")
        return checked

    def _redirect_handler(self):
        policy = self

        class SameOriginRedirectHandler(request.HTTPRedirectHandler):
            def redirect_request(self, req, fp, code, msg, headers, newurl):
                return super().redirect_request(
                    req, fp, code, msg, headers, policy.validate(newurl)
                )

        return SameOriginRedirectHandler

    def open(self, req, timeout=60):
        return self._opener.open(req, timeout=timeout)
