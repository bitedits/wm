// wm_x11.c
// Erlang X11 Port with command parsing (C99)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/select.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/Xatom.h>
#include <X11/keysym.h>

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

// Custom X11 error handler
static int xerror_handler(Display *d, XErrorEvent *e) {
    char msg[256];
    XGetErrorText(d, e->error_code, msg, sizeof(msg));
    send_event("LOG error X11 Error: %s (request %d)", msg, e->request_code);
    return 0; // Prevent crash
}

static unsigned long get_color(const char *hex_str) {
    XColor exact, closest;
    if (XAllocNamedColor(dpy, DefaultColormap(dpy, screen), hex_str, &exact, &closest)) {
        return closest.pixel;
    }
    return BlackPixel(dpy, screen);
}

static int parse_command(char *line, char *argv[], int max_args) {
    int argc = 0;
    char *token = strtok(line, " ");
    while (token && argc < max_args) {
        argv[argc++] = token;
        token = strtok(NULL, " ");
    }
    return argc;
}

static void process_erlang_command(char *buffer) {
    char *argv[16];
    int argc = parse_command(buffer, argv, 16);
    if (argc == 0) return;

    if (strcmp(argv[0], "PING") == 0) {
        send_event("EVENT Pong 0");
    } else if (strcmp(argv[0], "MAP_WINDOW") == 0 && argc >= 2) {
        Window w = strtoul(argv[1], NULL, 0);
        send_event("LOG info X11 Mapped Window %lx", w);
        XMapWindow(dpy, w);
    } else if (strcmp(argv[0], "UNMAP_WINDOW") == 0 && argc >= 2) {
        Window w = strtoul(argv[1], NULL, 0);
        XUnmapWindow(dpy, w);
    } else if (strcmp(argv[0], "MOVE_RESIZE") == 0 && argc >= 6) {
        Window w = strtoul(argv[1], NULL, 0);
        int x = atoi(argv[2]);
        int y = atoi(argv[3]);
        int width = atoi(argv[4]);
        int height = atoi(argv[5]);
        XMoveResizeWindow(dpy, w, x, y, width, height);
    } else if (strcmp(argv[0], "SET_FOCUS") == 0 && argc >= 2) {
        Window w = strtoul(argv[1], NULL, 0);
        XSetInputFocus(dpy, w, RevertToPointerRoot, CurrentTime);
        XRaiseWindow(dpy, w);
    } else if (strcmp(argv[0], "SET_BORDER_COLOR") == 0 && argc >= 3) {
        Window w = strtoul(argv[1], NULL, 0);
        unsigned long pixel = get_color(argv[2]);
        XSetWindowBorder(dpy, w, pixel);
    } else if (strcmp(argv[0], "SET_BORDER_WIDTH") == 0 && argc >= 3) {
        Window w = strtoul(argv[1], NULL, 0);
        unsigned int width = atoi(argv[2]);
        XSetWindowBorderWidth(dpy, w, width);
    }
}

int main(void) {
    XSetErrorHandler(xerror_handler);
    
    dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "ERROR: Cannot open X display\n");
        return 1;
    }

    screen = DefaultScreen(dpy);
    root = RootWindow(dpy, screen);

    XSelectInput(dpy, root, SubstructureRedirectMask | SubstructureNotifyMask |
                           KeyPressMask | ButtonPressMask | EnterWindowMask);
    XSync(dpy, False);

    log_info("X11 Port started");
    send_event("READY");

    int x11_fd = ConnectionNumber(dpy);
    
    // Set stdin to non-blocking
    int flags = fcntl(STDIN_FILENO, F_GETFL, 0);
    fcntl(STDIN_FILENO, F_SETFL, flags | O_NONBLOCK);

    char in_buf[BUFFER_SIZE];
    int in_pos = 0;

    while (1) {
        fd_set in_fds;
        FD_ZERO(&in_fds);
        FD_SET(STDIN_FILENO, &in_fds);
        FD_SET(x11_fd, &in_fds);

        int max_fd = (x11_fd > STDIN_FILENO) ? x11_fd : STDIN_FILENO;

        // Process pending X events before selecting
        while (XPending(dpy)) {
            XEvent ev;
            XNextEvent(dpy, &ev);
            switch (ev.type) {
                case MapRequest:
                    send_event("EVENT MapRequest %lx", ev.xmaprequest.window);
                    // CTWM: Select input on this window to get EnterNotify etc.
                    XSelectInput(dpy, ev.xmaprequest.window, EnterWindowMask | PropertyChangeMask);
                    break;
                case ConfigureRequest:
                    send_event("EVENT ConfigureRequest %lx %d %d %d %d %d",
                        ev.xconfigurerequest.window,
                        ev.xconfigurerequest.x, ev.xconfigurerequest.y,
                        ev.xconfigurerequest.width, ev.xconfigurerequest.height,
                        ev.xconfigurerequest.border_width);
                    break;
                case UnmapNotify:
                    send_event("EVENT UnmapNotify %lx", ev.xunmap.window);
                    break;
                case DestroyNotify:
                    send_event("EVENT DestroyNotify %lx", ev.xdestroywindow.window);
                    break;
                case EnterNotify:
                    send_event("EVENT EnterNotify %lx", ev.xcrossing.window);
                    break;
                case KeyPress: {
                    KeySym sym = XKeycodeToKeysym(dpy, ev.xkey.keycode, 0);
                    char *sym_name = XKeysymToString(sym);
                    if (!sym_name) sym_name = "Unknown";
                    send_event("EVENT KeyPress %lx %s %u",
                        ev.xkey.window, sym_name, ev.xkey.state);
                    break;
                }
            }
        }
        XFlush(dpy); // Flush any outgoing commands

        int ret = select(max_fd + 1, &in_fds, NULL, NULL, NULL);
        if (ret < 0) {
            break; // Error or signal
        }

        if (FD_ISSET(STDIN_FILENO, &in_fds)) {
            int n = read(STDIN_FILENO, in_buf + in_pos, BUFFER_SIZE - in_pos - 1);
            if (n <= 0) {
                // EOF or error
                break;
            }
            in_pos += n;
            in_buf[in_pos] = '\0';

            // Find newlines and process
            char *start = in_buf;
            char *newline;
            while ((newline = strchr(start, '\n')) != NULL) {
                *newline = '\0';
                
                if (strcmp(start, "SHUTDOWN") == 0) {
                    XCloseDisplay(dpy);
                    log_info("X11 Port shutdown");
                    return 0;
                }
                
                process_erlang_command(start);
                start = newline + 1;
            }

            // Move remaining data to front
            int remain = in_buf + in_pos - start;
            if (remain > 0) {
                memmove(in_buf, start, remain);
            }
            in_pos = remain;
        }
    }

    XCloseDisplay(dpy);
    return 0;
}
