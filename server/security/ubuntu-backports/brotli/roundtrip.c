/* Ordinary valid-input API/streaming control; no malformed stream or CVE trigger. */
#include <brotli/decode.h>
#include <brotli/encode.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int check(const unsigned char *input, size_t size, int quality) {
  size_t capacity = BrotliEncoderMaxCompressedSize(size);
  unsigned char *compressed = malloc(capacity ? capacity : 1);
  unsigned char *output = malloc(size + 1);
  size_t compressed_size = capacity, output_size = size + 1;
  if (!compressed || !output) return 1;
  if (!BrotliEncoderCompress(quality, BROTLI_DEFAULT_WINDOW, BROTLI_MODE_GENERIC,
                            size, input, &compressed_size, compressed)) return 2;
  if (BrotliDecoderDecompress(compressed_size, compressed, &output_size, output)
          != BROTLI_DECODER_RESULT_SUCCESS || output_size != size ||
      memcmp(input, output, size)) return 3;
  const size_t chunks[] = {1, 7, 64};
  for (size_t c = 0; c < sizeof(chunks) / sizeof(chunks[0]); ++c) {
    BrotliDecoderState *state = BrotliDecoderCreateInstance(NULL, NULL, NULL);
    size_t consumed = 0, produced = 0;
    BrotliDecoderResult result = BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT;
    if (!state) return 4;
    for (size_t iteration = 0; iteration < compressed_size + size + 16; ++iteration) {
      size_t available_in = compressed_size - consumed;
      if (available_in > chunks[c]) available_in = chunks[c];
      size_t available_out = size + 1 - produced;
      if (available_out > chunks[c]) available_out = chunks[c];
      const unsigned char *next_in = compressed + consumed;
      unsigned char *next_out = output + produced;
      size_t in_before = available_in, out_before = available_out;
      result = BrotliDecoderDecompressStream(state, &available_in, &next_in,
                                             &available_out, &next_out, NULL);
      consumed += in_before - available_in;
      produced += out_before - available_out;
      if (result == BROTLI_DECODER_RESULT_SUCCESS) break;
      if (result == BROTLI_DECODER_RESULT_ERROR ||
          (in_before == available_in && out_before == available_out)) return 5;
    }
    if (result != BROTLI_DECODER_RESULT_SUCCESS || consumed != compressed_size ||
        produced != size || !BrotliDecoderIsFinished(state) ||
        memcmp(input, output, size)) return 6;
    BrotliDecoderDestroyInstance(state);
  }
  free(compressed);
  free(output);
  return 0;
}

int main(void) {
  unsigned char repeated[8192];
  for (size_t n = 0; n < sizeof(repeated); ++n) repeated[n] = (unsigned char)(n % 251);
  const unsigned char text[] = "PastureStack ordinary Brotli API and streaming control.\n";
  const int qualities[] = {0, 1, 6, 9, 11};
  for (size_t q = 0; q < sizeof(qualities) / sizeof(qualities[0]); ++q) {
    if (check(text, 0, qualities[q]) || check(text, sizeof(text) - 1, qualities[q]) ||
        check(repeated, sizeof(repeated), qualities[q])) return 1;
  }
  puts("PASS: 15 valid roundtrips, 45 streaming roundtrips, three linked SONAMEs");
  return 0;
}
