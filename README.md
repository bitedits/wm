Sokhatsky WM
============

Here’s a clearer, more concrete comparison of what Erlang implementations of these four
window managers would actually look like, focused on the differences that matter when you share one C99 X11 Port.
These managers I would like you to take into account!

## High-level comparison

Aspect         TWM (Erlang)             CTWM (Erlang)                  DWM (Erlang)                    OXWM (Erlang)
Style          Classic stacking + tabs  Stacking + virtual workspaces  Dynamic tiling (master/stack)   Modern dynamic tiling + rich config
Complexity     Lowest                   Low–Medium                     Medium                          Highest
State          Simple window list/focus Windows + workspaces + icons   Tags (bitmasks/clients/layouts) Tags/multi-layout/key-chords/status bar
Layout         Almost none              Minimal (stacking/workspace)   Pure function layout/2          Multiple pure layout functions + runtime switch
Configuration  Text                     Erlang terms                   Compile-time                    Full DSL Erlang

## How the Erlang architecture differs

Common skeleton (what you already sketched is correct):

```
wm
├── wm_sup
├── wm_x11            % shared C99 Port (XNextEvent → Erlang messages)
├── wm_event          % receives Port messages, dispatches
├── wm_windows        % gen_server: window registry + focus
├── wm_layout         % pure functions (or gen_server for stateful layouts)
├── wm_config         % load + hot-reload
└── wm_keybind        % key-chord state machine
```

## TWM-style (easiest)

* wm_windows is basically a map of WindowId → #win{...}.
* Almost no layout engine — you just reparent, draw titlebars/tabs, and let the user move/resize.
* Event loop mostly reacts to ConfigureRequest, MapRequest, ButtonPress, KeyPress.
* Config is tiny (colors, fonts, a few keybindings).
* Perfect first project: you learn the Port ↔ Erlang protocol thoroughly.

## CTWM-style (recommended first real target)

* Add a wm_workspace gen_server (or one process per workspace).
* Windows can belong to multiple workspaces.
* Icon manager becomes another small gen_server.
* Still stacking, so layout code stays simple.
* Hot-reload of workspace names/colors is trivial with Erlang code loading.
* You get the “multiple desktops” feeling without the complexity of tiling algorithms.

## DWM-style (where Erlang really shines)

Core idea: layout is a pure function

     layout(Clients, Screen, #{mfact := M, nmaster := N, layout := tiling}) ->

* Tags are just bitmasks (1 bsl Tag).
* wm_windows keeps a list of clients; wm_layout is pure (or a tiny gen_server that only caches the last result).
* Keybindings become very clean with pattern matching.
* Adding new layouts (monocle, grid, etc.) is just adding another function clause.
* This is the sweet spot for Erlang: immutable data + pure functions + message-passing for the X11 side.

## OXWM-style (most ambitious)

Everything from DWM plus:

* Multiple simultaneous layouts (tiling / monocle / grid / tabbed / floating).
* Full key-chord state machine (wm_keybind becomes a proper state machine).
* Status bar blocks (you would spawn small processes or use a separate Port for drawing).
* Rich configuration DSL (you can embed a small Lua-like interpreter or just use Erlang terms + hot code loading).
* Multi-monitor support becomes more important.

You start needing more careful supervision trees and possibly a wm_bar process.
Hot-reload of the entire config without killing windows is very natural in Erlang (exactly what OXWM tries to do with Lua).

## Practical recommendation for your project

* Start with a minimal TWM-like core
* Get the C99 Port solid (XOpenDisplay, XNextEvent, reparenting, basic focus, titlebars).
* This is 70 % of the hard X11 work.
* Then implement CTWM-style workspaces
* This gives you a usable stacking WM quickly and teaches you multi-desktop logic.
* Next, add a pure DWM-style tiling layout engine
* Keep the stacking code and just add a layout module. Switching between stacking and tiling becomes a config option.
* OXWM features last
* Key chords, status bar, multiple layouts, fancy config language — these are pure Erlang work once the X11 Port and window model are stable.

## Shared C99 Port surface (keep it tiny)

wm_x11.c (minimal):

- XOpenDisplay
- SelectInput on root
- XNextEvent loop → write binary messages to stdout
- Commands from Erlang via stdin: MapWindow, ConfigureWindow, SetInputFocus, GrabKey, etc.

