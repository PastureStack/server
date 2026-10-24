/* Test-only embedding control. No compiler or probe enters a product image. */
#include <dlfcn.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include "jq.h"

struct jq_api {
  jq_state *(*init)(void);
  void (*teardown)(jq_state **);
  int (*compile)(jq_state *, const char *);
  void (*start)(jq_state *, jv, int);
  jv (*next)(jq_state *);
  jv (*parse)(const char *);
  jv_kind (*kind)(jv);
  jv (*copy_value)(jv);
  int (*invalid_has_message)(jv);
  void (*free_value)(jv);
};

enum { THREADS = 4, ITERATIONS = 128 };
struct worker {
  const struct jq_api *api;
  pthread_barrier_t *barrier;
  int failed;
};

static void *evaluate(void *argument) {
  struct worker *worker = argument;
  const struct jq_api *api = worker->api;
  jq_state *state = api->init();
  if (!state || !api->compile(state, "sort_by(.k) | map(.k) == [1,2,3]")) {
    worker->failed = 1;
  }
  /* All independent jq states reach the runtime sort together, without sleeps. */
  int barrier = pthread_barrier_wait(worker->barrier);
  if (barrier != 0 && barrier != PTHREAD_BARRIER_SERIAL_THREAD) {
    worker->failed = 1;
  }
  for (int iteration = 0; !worker->failed && iteration < ITERATIONS; ++iteration) {
    jv input = api->parse("[{\"k\":3},{\"k\":1},{\"k\":2}]");
    api->start(state, input, 0);
    jv result = api->next(state);
    if (api->kind(result) != JV_KIND_TRUE) {
      worker->failed = 1;
    }
    api->free_value(result);
    jv end = api->next(state);
    if (api->kind(end) != JV_KIND_INVALID || api->invalid_has_message(api->copy_value(end))) {
      worker->failed = 1;
    }
    api->free_value(end);
  }
  if (state) api->teardown(&state);
  return NULL;
}

int main(void) {
  /* Resolve every relocation before starting threads. Linking the executable
     against libjq/libm would mask a missing shared-library dependency. */
  void *library = dlopen("libjq.so.1", RTLD_NOW | RTLD_LOCAL);
  if (!library) {
    fprintf(stderr, "libjq RTLD_NOW failed: %s\n", dlerror());
    return EXIT_FAILURE;
  }
  struct jq_api api;
#define RESOLVE(field, name) do { \
  dlerror(); \
  api.field = (__typeof__(api.field))dlsym(library, name); \
  const char *error = dlerror(); \
  if (error || !api.field) { \
    fprintf(stderr, "libjq symbol %s failed: %s\n", name, error ? error : "null"); \
    return EXIT_FAILURE; \
  } \
} while (0)
  RESOLVE(init, "jq_init");
  RESOLVE(teardown, "jq_teardown");
  RESOLVE(compile, "jq_compile");
  RESOLVE(start, "jq_start");
  RESOLVE(next, "jq_next");
  RESOLVE(parse, "jv_parse");
  RESOLVE(kind, "jv_get_kind");
  RESOLVE(copy_value, "jv_copy");
  RESOLVE(invalid_has_message, "jv_invalid_has_msg");
  RESOLVE(free_value, "jv_free");
#undef RESOLVE
  pthread_barrier_t barrier;
  if (pthread_barrier_init(&barrier, NULL, THREADS) != 0) return EXIT_FAILURE;
  pthread_t threads[THREADS];
  struct worker workers[THREADS];
  for (int index = 0; index < THREADS; ++index) {
    workers[index] = (struct worker){ &api, &barrier, 0 };
    if (pthread_create(&threads[index], NULL, evaluate, &workers[index]) != 0) {
      return EXIT_FAILURE;
    }
  }
  int failed = 0;
  for (int index = 0; index < THREADS; ++index) {
    if (pthread_join(threads[index], NULL) != 0 || workers[index].failed) failed = 1;
  }
  if (pthread_barrier_destroy(&barrier) != 0 || dlclose(library) != 0) failed = 1;
  if (failed) {
    fputs("libjq embedding/TLS control failed\n", stderr);
    return EXIT_FAILURE;
  }
  printf("PASS libjq RTLD_NOW, %d independent threads, %d runtime sorts per thread\n",
         THREADS, ITERATIONS);
  return EXIT_SUCCESS;
}
