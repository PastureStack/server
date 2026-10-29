/* Reuse the existing actual-library control, then reject an ordinary truncation. */
#define main qualified_brotli_roundtrip
#include "../security/ubuntu-backports/bundle/installer/testdata/consumer-brotli-probe.c"
#undef main

int main(void) {
  if (qualified_brotli_roundtrip()) return 1;
  void *encoder = dlopen("libbrotlienc.so.1", RTLD_NOW | RTLD_LOCAL);
  void *decoder = dlopen("libbrotlidec.so.1", RTLD_NOW | RTLD_LOCAL);
  if (!encoder || !decoder) return 2;
  BROTLI_BOOL (*compress)(int, int, BrotliEncoderMode, size_t, const uint8_t *, size_t *, uint8_t *) =
      (BROTLI_BOOL (*)(int, int, BrotliEncoderMode, size_t, const uint8_t *, size_t *, uint8_t *))
      dlsym(encoder, "BrotliEncoderCompress");
  BrotliDecoderResult (*decompress)(size_t, const uint8_t *, size_t *, uint8_t *) =
      (BrotliDecoderResult (*)(size_t, const uint8_t *, size_t *, uint8_t *))
      dlsym(decoder, "BrotliDecoderDecompress");
  if (!compress || !decompress) return 3;
  const uint8_t input[] = "PastureStack ordinary truncated-input guard; no crafted CVE stream.";
  uint8_t encoded[1024], output[1024];
  size_t size = sizeof(encoded), decoded = sizeof(output);
  if (!compress(6, BROTLI_DEFAULT_WINDOW, BROTLI_MODE_GENERIC, sizeof(input), input, &size, encoded) ||
      size < 4 || decompress(size / 2, encoded, &decoded, output) == BROTLI_DECODER_RESULT_SUCCESS) return 4;
  if (dlclose(decoder) || dlclose(encoder)) return 5;
  puts("PASS: truncated ordinary input rejected");
  return 0;
}
