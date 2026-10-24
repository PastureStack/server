/* Exercise the actual XRenderQueryFormats reply boundary against an isolated Xvfb.
 * The original source safely reaches allocation after the malformed header;
 * patched source must reject it before allocating. No malformed payload is sent.
 */
#include <X11/Xlibint.h>
#include <X11/extensions/Xrender.h>
#include <X11/extensions/renderproto.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static int armed, injected, after_reply, allocations;
extern Status __real__XReply(Display *, xReply *, int, Bool);
extern void *__real_calloc(size_t, size_t);

void *__wrap_calloc(size_t n, size_t size)
{
    if (after_reply)
        allocations++;
    return __real_calloc(n, size);
}

Status __wrap__XReply(Display *display, xReply *reply, int extra, Bool discard)
{
    Status result = __real__XReply(display, reply, extra, discard);
    if (armed && result) {
        xRenderQueryPictFormatsReply *formats = (void *) reply;
        if (formats->numScreens == 0 || formats->numScreens > 100 ||
            formats->numSubpixel != formats->numScreens) {
            fprintf(stderr, "unexpected isolated Xvfb reply shape\n");
            exit(3);
        }
        formats->numSubpixel = formats->numScreens + 1;
        injected++;
        after_reply = 1;
    }
    return result;
}

int main(int argc, char **argv)
{
    Display *display = XOpenDisplay(NULL);
    if (!display || !XRenderQueryFormats(display) ||
        !XRenderFindStandardFormat(display, PictStandardARGB32)) {
        fprintf(stderr, "valid XRender control failed\n");
        return 3;
    }
    XCloseDisplay(display);
    if (argc == 2 && strcmp(argv[1], "--valid-only") == 0) {
        puts("packaged valid XRender control: PASS");
        return 0;
    }
    display = XOpenDisplay(NULL);
    if (!display)
        return 3;
    armed = 1;
    Status status = XRenderQueryFormats(display);
    armed = after_reply = 0;
    XCloseDisplay(display);
    if (injected != 1 || status != 0) {
        fprintf(stderr, "malformed reply rejection control failed\n");
        return 3;
    }
    if (allocations != 0) {
        fprintf(stderr, "malformed header reached allocation: %d\n", allocations);
        return 2;
    }
    puts("valid control and malformed header rejected before allocation: PASS");
    return 0;
}
