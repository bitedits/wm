-module(wm_config_SUITE).
-include_lib("common_test/include/ct.hrl").

-export([all/0, init_per_suite/1, end_per_suite/1, init_per_testcase/2, end_per_testcase/2]).
-export([test_load_valid_config/1]).

all() ->
    [test_load_valid_config].

init_per_suite(Config) -> Config.
end_per_suite(_Config) -> ok.

init_per_testcase(_TestCase, Config) ->
    {ok, Pid} = wm_config:start_link(),
    [{config_pid, Pid} | Config].

end_per_testcase(_TestCase, Config) ->
    Pid = ?config(config_pid, Config),
    gen_server:stop(Pid),
    ok.

test_load_valid_config(_Config) ->
    Config = wm_config:get_config(),
    true = is_list(Config),
    {workspaces, _} = lists:keyfind(workspaces, 1, Config),
    {colors, _} = lists:keyfind(colors, 1, Config),
    ok.
