-module(wm_windows_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([test_register_window/1, test_unregister_window/1, test_duplicate_register/1, test_unregister_nonexistent/1]).

all() ->
    [test_register_window, test_unregister_window, test_duplicate_register, test_unregister_nonexistent].

init_per_suite(Config) ->
    Config.

end_per_suite(_Config) ->
    ok.

init_per_testcase(_TestCase, Config) ->
    {ok, Pid} = wm_windows:start_link(),
    [{windows_pid, Pid} | Config].

end_per_testcase(_TestCase, Config) ->
    Pid = ?config(windows_pid, Config),
    gen_server:stop(Pid),
    ok.

test_register_window(_Config) ->
    wm_windows:register_window(10),
    wm_windows:register_window(20),
    timer:sleep(50),
    Windows = wm_windows:get_all(),
    true = lists:member(10, Windows),
    true = lists:member(20, Windows),
    2 = length(Windows),
    ok.

test_unregister_window(_Config) ->
    wm_windows:register_window(10),
    timer:sleep(50),
    wm_windows:unregister_window(10),
    timer:sleep(50),
    [] = wm_windows:get_all(),
    ok.

test_duplicate_register(_Config) ->
    wm_windows:register_window(30),
    wm_windows:register_window(30),
    timer:sleep(50),
    Windows = wm_windows:get_all(),
    [30] = Windows, % Should be idempotent and unique
    ok.

test_unregister_nonexistent(_Config) ->
    wm_windows:unregister_window(999),
    timer:sleep(50),
    [] = wm_windows:get_all(),
    ok.
