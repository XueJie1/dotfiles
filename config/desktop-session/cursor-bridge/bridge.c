#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Only change cursor settings after a successful connection to this session's
 * satellite. Native Wayland processes retain the compositor's logical size. */
static void configure(const char *display) {
    const char *desktop = getenv("XDG_CURRENT_DESKTOP");
    const char *home = getenv("HOME");
    if (!desktop || !strcasestr(desktop, "sway") || !home) return;
    if (!display) display = getenv("DISPLAY");
    if (!display) return;
    char path[4096], line[4096], theme[2048] = "", size[32] = "", target[128] = "";
    if (snprintf(path, sizeof(path), "%s/.config/desktop-session/x11.env", home) >= (int)sizeof(path)) return;
    FILE *file = fopen(path, "r");
    if (!file) return;
    while (fgets(line, sizeof(line), file)) {
        line[strcspn(line, "\r\n")] = 0;
        if (!strncmp(line, "XCURSOR_THEME=", 14)) snprintf(theme, sizeof(theme), "%s", line + 14);
        if (!strncmp(line, "XCURSOR_SIZE=", 13)) snprintf(size, sizeof(size), "%s", line + 13);
        if (!strncmp(line, "DISPLAY=", 8)) snprintf(target, sizeof(target), "%s", line + 8);
    }
    fclose(file);
    char *end;
    long number = strtol(size, &end, 10);
    if (strcmp(display, target) || !*theme || number <= 0 || number > 512 || *end) return;
    setenv("XCURSOR_THEME", theme, 1);
    setenv("XCURSOR_SIZE", size, 1);
    if (getenv("DESKTOP_CURSOR_DEBUG"))
        fprintf(stderr, "cursor-bridge: X11 %s theme=%s size=%s\n", display, theme, size);
}

void *XOpenDisplay(const char *name) {
    void *(*next)(const char *) = dlsym(RTLD_NEXT, "XOpenDisplay");
    if (!next) return NULL;
    void *connection = next(name);
    if (connection) configure(name);
    return connection;
}

void *xcb_connect(const char *name, int *screen) {
    void *(*next)(const char *, int *) = dlsym(RTLD_NEXT, "xcb_connect");
    if (!next) return NULL;
    void *connection = next(name, screen);
    int (*error)(void *) = dlsym(RTLD_NEXT, "xcb_connection_has_error");
    if (connection && error && !error(connection)) configure(name);
    return connection;
}

void *xcb_connect_to_display_with_auth_info(const char *name, void *auth, int *screen) {
    void *(*next)(const char *, void *, int *) = dlsym(RTLD_NEXT, "xcb_connect_to_display_with_auth_info");
    if (!next) return NULL;
    void *connection = next(name, auth, screen);
    int (*error)(void *) = dlsym(RTLD_NEXT, "xcb_connection_has_error");
    if (connection && error && !error(connection)) configure(name);
    return connection;
}

