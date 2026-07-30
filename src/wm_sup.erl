-module(wm_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_one,
                 intensity => 1,
                 period => 5},

    ChildSpecs = [
        #{id => wm_config,
          start => {wm_config, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_config]},
        #{id => wm_windows,
          start => {wm_windows, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_windows]},
        #{id => wm_workspace,
          start => {wm_workspace, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_workspace]},
        #{id => wm_event,
          start => {wm_event, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_event]},
        #{id => wm_keybind,
          start => {wm_keybind, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_keybind]},
        #{id => wm_x11,
          start => {wm_x11, start_link, []},
          restart => permanent,
          shutdown => 5000,
          type => worker,
          modules => [wm_x11]}
    ],

    {ok, {SupFlags, ChildSpecs}}.
