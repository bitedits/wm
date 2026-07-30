-module(wm_x11_port_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([test_port_boot_and_ready/1, test_port_shutdown/1, test_invalid_window_error_handling/1]).

all() ->
    [test_port_boot_and_ready, test_port_shutdown, test_invalid_window_error_handling].

init_per_suite(Config) ->
    os:cmd("Xvfb :99 -screen 0 1024x768x24 &"),
    os:putenv("DISPLAY", ":99"),
    timer:sleep(1000),
    Config.

end_per_suite(_Config) ->
    os:cmd("pkill Xvfb"),
    ok.

init_per_testcase(_TestCase, Config) ->
    ok = application:start(wm),
    timer:sleep(200),
    Config.

end_per_testcase(_TestCase, _Config) ->
    application:stop(wm),
    ok.

test_port_boot_and_ready(_Config) ->
    Pid = whereis(wm_x11),
    true = is_process_alive(Pid),
    ok.

test_port_shutdown(_Config) ->
    %% Test covered by end_per_testcase which stops the app, 
    %% we just verify process died
    Pid = whereis(wm_x11),
    application:stop(wm),
    timer:sleep(200),
    false = is_process_alive(Pid),
    %% Restart it so end_per_testcase doesn't crash
    ok = application:start(wm),
    ok.

test_invalid_window_error_handling(_Config) ->
    Pid = whereis(wm_x11),
    true = is_process_alive(Pid),
    
    %% Send command for a non-existent window (BadWindow error in X11)
    wm_x11:map_window(999999),
    timer:sleep(200),
    
    %% Port should STILL be alive because of XSetErrorHandler
    true = is_process_alive(Pid),
    ok.
