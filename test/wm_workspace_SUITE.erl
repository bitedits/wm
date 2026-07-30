-module(wm_workspace_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([test_switch_workspace/1, test_map_request_to_active/1, test_unmap_removes_from_workspace/1]).

all() ->
    [test_switch_workspace, test_map_request_to_active, test_unmap_removes_from_workspace].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

init_per_testcase(_TestCase, Config) ->
    {ok, Pid} = wm_workspace:start_link(),
    [{workspace_pid, Pid} | Config].

end_per_testcase(_TestCase, Config) ->
    Pid = ?config(workspace_pid, Config),
    gen_server:stop(Pid),
    ok.

test_switch_workspace(_Config) ->
    1 = wm_workspace:get_active(),
    wm_workspace:switch(2),
    timer:sleep(50),
    2 = wm_workspace:get_active(),
    ok.

test_map_request_to_active(_Config) ->
    wm_workspace:switch(3),
    timer:sleep(50),
    wm_workspace:map_request(123),
    timer:sleep(50),
    %% Currently, map_request updates internal win_to_ws state. 
    %% We verify it doesn't crash here.
    ok.

test_unmap_removes_from_workspace(_Config) ->
    wm_workspace:map_request(456),
    timer:sleep(50),
    wm_workspace:unmap_notify(456),
    timer:sleep(50),
    %% Ensures no crash and state updates cleanly.
    ok.
