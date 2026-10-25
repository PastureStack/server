#!/usr/bin/env python3
"""Check the installed qualified Brotli library with ordinary valid inputs."""
import ctypes
import json
from pathlib import Path
import subprocess


manifest = json.loads(Path('/usr/share/pasturestack/security/ubuntu-backports/manifest.json').read_text())
expected = [package['version'] for package in manifest['packages'] if package['name'] == 'libbrotli1']
assert len(expected) == 1, 'Qualified Brotli package is absent or ambiguous'
actual = subprocess.check_output(['dpkg-query', '-W', '-f=${Version}', 'libbrotli1'], text=True)
assert actual == expected[0], 'Installed Brotli does not match the qualified package'
encoder = ctypes.CDLL('libbrotlienc.so.1')
decoder = ctypes.CDLL('libbrotlidec.so.1')
size = ctypes.c_size_t
encoder.BrotliEncoderMaxCompressedSize.argtypes = [size]
encoder.BrotliEncoderMaxCompressedSize.restype = size
encoder.BrotliEncoderCompress.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.c_int,
                                        size, ctypes.c_void_p, ctypes.POINTER(size), ctypes.c_void_p]
encoder.BrotliEncoderCompress.restype = ctypes.c_int
decoder.BrotliDecoderDecompress.argtypes = [size, ctypes.c_void_p, ctypes.POINTER(size), ctypes.c_void_p]
decoder.BrotliDecoderDecompress.restype = ctypes.c_int
for content in (b'', b'PastureStack ordinary Brotli runtime control\n' * 32, bytes(range(256))):
    encoded_size = size(encoder.BrotliEncoderMaxCompressedSize(len(content)))
    encoded = ctypes.create_string_buffer(max(1, encoded_size.value))
    assert encoder.BrotliEncoderCompress(5, 22, 0, len(content), content,
                                        ctypes.byref(encoded_size), encoded) == 1
    decoded_size = size(max(1, len(content)))
    decoded = ctypes.create_string_buffer(decoded_size.value)
    assert decoder.BrotliDecoderDecompress(encoded_size.value, encoded,
                                          ctypes.byref(decoded_size), decoded) == 1
    assert decoded.raw[:decoded_size.value] == content
print(json.dumps({'status': 'PASS', 'package': 'libbrotli1', 'version': actual,
                  'bundleVersion': manifest['bundleVersion'], 'ordinaryRoundTrips': 3,
                  'publicSonameControls': ['libbrotlienc.so.1', 'libbrotlidec.so.1'],
                  'securityTriggerExecuted': False}, sort_keys=True))
