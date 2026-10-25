/* Disposable consumer linkage of the actual installed libraries; valid input only. */
#include <brotli/decode.h>
#include <brotli/encode.h>
#include <dlfcn.h>
#include <stdio.h>
#include <string.h>

int main(void) {
  const char *names[] = {"libbrotlicommon.so.1", "libbrotlidec.so.1", "libbrotlienc.so.1"};
  void *handles[3];
  for (size_t n = 0; n < 3; ++n) {
    handles[n] = dlopen(names[n], RTLD_NOW | RTLD_LOCAL);
    if (!handles[n]) { fprintf(stderr, "%s\n", dlerror()); return 1; }
  }
  BROTLI_BOOL (*compress)(int, int, BrotliEncoderMode, size_t, const uint8_t *, size_t *, uint8_t *) =
      (BROTLI_BOOL (*)(int, int, BrotliEncoderMode, size_t, const uint8_t *, size_t *, uint8_t *))
      dlsym(handles[2], "BrotliEncoderCompress");
  BrotliDecoderResult (*decompress)(size_t, const uint8_t *, size_t *, uint8_t *) =
      (BrotliDecoderResult (*)(size_t, const uint8_t *, size_t *, uint8_t *))
      dlsym(handles[1], "BrotliDecoderDecompress");
  if (!compress || !decompress) return 2;
  const uint8_t input[] = "PastureStack ordinary installed Brotli linkage control.";
  uint8_t compressed[1024], output[1024];
  size_t encoded = sizeof(compressed), decoded = sizeof(output);
  if (!compress(6, BROTLI_DEFAULT_WINDOW, BROTLI_MODE_GENERIC, sizeof(input), input, &encoded, compressed) ||
      decompress(encoded, compressed, &decoded, output) != BROTLI_DECODER_RESULT_SUCCESS ||
      decoded != sizeof(input) || memcmp(input, output, decoded)) return 3;
  for (size_t n = 3; n > 0; --n) if (dlclose(handles[n - 1])) return 4;
  puts("PASS: three installed Brotli SONAMEs RTLD_NOW, ordinary compression/decompression");
  return 0;
}
