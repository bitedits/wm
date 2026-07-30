// wm_x11.c
// Erlang X11 Port with command parsing (C99)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>

#define BUFFER_SIZE 4096

static Display *dpy = NULL;
static Window root = None;
static int screen = 0;

static void send_event(const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);
    vfprintf(stdout, fmt, args);
    fputc('\n', stdout);
    fflush(stdout);
    va_end(args);
}

static void log_info(const char *msg) {
    send_event("LOG info %s", msg);
}

static void log_error(const char *msg) {
    send_event("LOG error %s", msg);
}

// Simple tokenizer
static int parse_command(char *line, char *argv[], int max_args) {
    int argc = 0;
    char *token = strtok(line, " ");
    while (token && argc < max_args) {
        argv[argc++] = token;
        token = strtok(NULL, " ");
    }
    return argc;
}

int main(void) {
    dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "ERROR: Cannot open X display\n");
        return 1;
    }

    screen = DefaultScreen(dpy);
    root = RootWindow(dpy, screen);

    log_info("X11 Port started");
    send_event("READY");

    XSelectInput(dpy, root, SubstructureRedirectMask | SubstructureNotifyMask |
                           KeyPressMask | ButtonPressMask | EnterWindowMask);

    XSync(dpy, False);

    char buffer[BUFFER_SIZE];
    XEvent ev;
    char *argv[16];

    while (1) {
        // Process X11 events
        while (XPending(dpy)) {
            XNextEvent(dpy, &ev);
            switch (ev.type) {
                case MapRequest:
                    send_event("EVENT MapRequest 0x%lx", ev.xmaprequest.window);
                    XMapWindow(dpy, ev.xmaprequest.window);
                    break;

                case ConfigureRequest:
                    send_event("EVENT ConfigureRequest 0x%lx %d %d %d %d %d",
                        ev.xconfigurerequest.window,
                        ev.xconfigurerequest.x, ev.xconfigurerequest.y,
                        ev.xconfigurerequest.width, ev.xconfigurerequest.height,
                        ev.xconfigurerequest.border_width);
                    break;

                case KeyPress:
                    send_event("EVENT KeyPress 0x%lx %u %u",
                        ev.xkey.window, ev.xkey.keycode, ev.xkey.state);
                    break;

                default:
                    break;
            }
        }

        // Read command from Erlang
        if (fgets(buffer, sizeof(buffer), stdin)) {
            buffer[strcspn(buffer, "\n")] = '\0';
            if (buffer[0] == '\0') continue;

            int argc = parse_command(buffer, argv, 16);

            if (argc == 0) continue;

            if (strcmp(argv[0], "SHUTDOWN") == 0) {
                break;
            }
            else if (strcmp(argv[0], "PING") == 0) {
                send_event("EVENT Pong 0");
            }
            else if (strcmp(argv[0], "CREATE_WINDOW") == 0 && argc >= 7) {
                Window w = strtoul(argv[1], NULL, 0);
                int x = atoi(argv[2]);
                int y = atoi(argv[3]);
                int w_ = atoi(argv[4]);
                int h = atoi(argv[5]);
                int bw = atoi(argv[6]);

                XCreateSimpleWindow(dpy, root, x, y, w_, h, bw,
                                   BlackPixel(dpy, screen), WhitePixel(dpy, screen));
                send_event("EVENT WindowCreated 0x%lx", w);
            }
            else if (strcmp(argv[0], "MAP_WINDOW") == 0 && argc >= 2) {
                Window w = strtoul(argv[1], NULL, 0);
                XMapWindow(dpy, w);
            }
            else if (strcmp(argv[0], "MOVE_RESIZE") == 0 && argc >= 6) {
                Window w = strtoul(argv[1], NULL, 0);
                int x = atoi(argv[2]);
                int y = atoi(argv[3]);
                int width = atoi(argv[4]);
                int height = atoi(argv[5]);
                XMoveResizeWindow(dpy, w, x, y, width, height);
            }
            else if (strcmp(argv[0], "GRAB_KEY") == 0 && argc >= 3) {
                // TODO: Proper keysym -> keycode conversion
                log_info("GRAB_KEY command received (stub)");
            }
            else {
                send_event("LOG warn Unknown command: %s", argv[0]);
            }
        }

        usleep(8000); // ~8ms - good balance
    }

    XCloseDisplay(dpy);
    log_info("X11 Port shutdown");
    return 0;
}
