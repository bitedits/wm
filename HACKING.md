# Hacking on CTWM (Erlang)

Welcome to the internal documentation for developing and hacking on the CTWM Erlang backend.

Since the Window Manager operates entirely as a standard OTP application, it's incredibly easy
to introspect the state of the Window Manager, trace events, and manually control X11 windows
directly from the interactive Erlang shell.

## Starting the Development Environment

We use `Xephyr` on macOS to run a nested X server, allowing you to
visually test the window manager without risking crashing your main desktop.

To launch the environment:

```bash
./run_wm.sh
```

This script will:

1. Start XQuartz (if not running).
2. Start Xephyr on display `:1`.
3. Launch an `xterm` window inside Xephyr.
4. Launch the Erlang shell (`rebar3 shell`) in your terminal, with the `wm` application automatically started.

## Manipulating the WM from the Erlang Shell

Once the Erlang shell (`1>`) is running, you can manually interact with the `gen_server`
processes that make up the window manager. This is exactly how the internal layout engine and event dispatchers operate.

### 1. Window Registry (`wm_windows`)

To find out which windows the Window Manager is currently tracking:

```erlang
Windows = wm_windows:get_all().
[MyXterm | _] = Windows.
```

### 2. X11 Port Control (`wm_x11`)

You can send commands directly to the C Port to manipulate windows on the screen.
Try running these with `MyXterm` bound:

Move and Resize:

```erlang
wm_x11:move_resize(MyXterm, 100, 100, 600, 400).
```

Hide / Unmap a Window:

```erlang
wm_x11:unmap_window(MyXterm).
```

Show / Map a Window:

```erlang
wm_x11:map_window(MyXterm).
```

Set Input Focus:

```erlang
wm_x11:set_focus(MyXterm).
```

### 3. Workspace Management (`wm_workspace`)

The workspace manager tracks which windows belong to which virtual workspace (1-4).

Check the active workspace:

```erlang
wm_workspace:get_active().
```

Switch workspaces:

(Note: Right now this just updates internal state, but eventually it will trigger
bulk map/unmap commands to hide the previous workspace's windows).

```erlang
wm_workspace:switch(2).
```

### 4. Configuration (`wm_config`)

To view the parsed configuration from `priv/ctwm.config`:

```erlang
wm_config:get_config().
```

## Architecture Overview

- **`wm_x11`**: The C-node port driver. Handles the blocking X11 event loop in C and translates XEvents into string messages passed over stdin/stdout.
- **`wm_event`**: The central router. Receives events from `wm_x11` (like `MapRequest`, `UnmapNotify`, `EnterNotify`) and routes them to the appropriate state-tracking modules.
- **`wm_windows`**: A simple registry of all windows that currently exist.
- **`wm_workspace`**: Maps window IDs to workspace IDs.
- **`wm_layout`**: Pure, side-effect-free layout calculators for tiling and stacking.
- **`wm_keybind`**: Asynchronous handler for `KeyPress` events, mapping them to configured actions.
