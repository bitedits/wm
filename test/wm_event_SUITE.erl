-module(wm_event_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([test_map_request_dispatch/1, test_unmap_notify_dispatch/1, test_enter_notify_dispatch/1, test_unknown_event/1]).

all() ->
    [test_map_request_dispatch, test_unmap_notify_dispatch, test_enter_notify_dispatch, test_unknown_event].

init_per_suite(Config) ->
    %% Need Xvfb because wm_event triggers wm_x11 which uses port
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

test_map_request_dispatch(_Config) ->
    wm_event:dispatch(["MapRequest", "200"]),
    timer:sleep(100),
    true = lists:member(16#200, wm_windows:get_all()),
    ok.

test_unmap_notify_dispatch(_Config) ->
    wm_event:dispatch(["MapRequest", "300"]),
    timer:sleep(100),
    wm_event:dispatch(["UnmapNotify", "300"]),
    timer:sleep(100),
    false = lists:member(16#300, wm_windows:get_all()),
    ok.

test_enter_notify_dispatch(_Config) ->
    wm_event:dispatch(["EnterNotify", "400"]),
    timer:sleep(100),
    %% Verification is that it didn't crash while sending SET_FOCUS
    ok.

test_unknown_event(_Config) ->
    wm_event:dispatch(["SomethingRandom", "123"]),
    timer:sleep(100),
    ok.
