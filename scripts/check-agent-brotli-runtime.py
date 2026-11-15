#!/usr/bin/env python3
"""Check the installed qualified Brotli library with ordinary valid inputs."""
import ctypes
import json
import subprocess


actual = subprocess.check_output(['dpkg-query', '-W', '-f=${Version}', 'libbrotli1'], text=True)
assert actual == '1.2.0-3ubuntu0.1', 'Installed Brotli does not match USN-8956-1'
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
                  'ordinaryRoundTrips': 3,
                  'publicSonameControls': ['libbrotlienc.so.1', 'libbrotlidec.so.1'],
                  'securityTriggerExecuted': False}, sort_keys=True))
