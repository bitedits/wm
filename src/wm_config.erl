-module(wm_config).
-behaviour(gen_server).

-export([start_link/0, get_config/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {config = []}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

get_config() ->
    gen_server:call(?MODULE, get_config).

init([]) ->
    %% Try loading ctwm.config
    PrivDir = case code:priv_dir(wm) of
                  {error, bad_name} ->
                      filename:join([filename:dirname(code:which(?MODULE)), ".."]);
                  Dir -> Dir
              end,
    ConfigFile = filename:join([PrivDir, "ctwm.config"]),
    Config = case file:consult(ConfigFile) of
                 {ok, Terms} -> Terms;
                 {error, Reason} ->
                     io:format("Warning: Failed to load ~s: ~p~n", [ConfigFile, Reason]),
                     []
             end,
    {ok, #state{config = Config}}.

handle_call(get_config, _From, State) ->
    {reply, State#state.config, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
