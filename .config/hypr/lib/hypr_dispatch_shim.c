#define _GNU_SOURCE
#include <dlfcn.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>
#include <unistd.h>
#include <sys/socket.h>

static ssize_t (*real_write)(int, const void *, size_t) = NULL;
static ssize_t (*real_send)(int, const void *, size_t, int) = NULL;
static ssize_t (*real_sendmsg)(int, const struct msghdr *, int) = NULL;

static int rewrite_dispatch(const char *buf, size_t count, char *out, size_t outsz, size_t *outlen) {
    if (!buf || count < 18 || count >= outsz - 96)
        return 0;
    if (strncmp(buf, "dispatch ", 9) != 0)
        return 0;

    const char *p = buf + 9;
    if (strncmp(p, "workspace ", 10) == 0) {
        p += 10;
    } else if (strncmp(p, "focusworkspaceoncurrentmonitor ", 31) == 0) {
        p += 31;
    } else {
        return 0;
    }

    if (strncmp(p, "name:", 5) == 0)
        p += 5;

    const char *start = p;
    while ((size_t)(p - buf) < count && *p && *p != ' ' && *p != '\n' && *p != '\r')
        p++;
    size_t toklen = (size_t)(p - start);
    if (toklen == 0 || toklen > 64)
        return 0;

    char token[65];
    memcpy(token, start, toklen);
    token[toklen] = '\0';

    int numeric = toklen > 0;
    for (size_t i = 0; i < toklen; i++) {
        if (!isdigit((unsigned char)token[i])) {
            numeric = 0;
            break;
        }
    }

    int n;
    if (numeric)
        n = snprintf(out, outsz, "dispatch hl.dsp.focus({ workspace = %s })", token);
    else
        n = snprintf(out, outsz, "dispatch hl.dsp.focus({ workspace = \"%s\" })", token);

    if (n < 0 || (size_t)n >= outsz)
        return 0;
    *outlen = (size_t)n;
    return 1;
}

ssize_t write(int fd, const void *buf, size_t count) {
    if (!real_write)
        real_write = dlsym(RTLD_NEXT, "write");
    char out[512];
    size_t outlen = 0;
    if (rewrite_dispatch(buf, count, out, sizeof out, &outlen))
        return real_write(fd, out, outlen);
    return real_write(fd, buf, count);
}

ssize_t send(int sockfd, const void *buf, size_t len, int flags) {
    if (!real_send)
        real_send = dlsym(RTLD_NEXT, "send");
    char out[512];
    size_t outlen = 0;
    if (rewrite_dispatch(buf, len, out, sizeof out, &outlen))
        return real_send(sockfd, out, outlen, flags);
    return real_send(sockfd, buf, len, flags);
}
