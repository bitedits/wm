-module(wm_windows).
-behaviour(gen_server).

-export([start_link/0, register_window/1, unregister_window/1, get_all/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {windows = []}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

register_window(WinId) ->
    gen_server:cast(?MODULE, {register, WinId}).

unregister_window(WinId) ->
    gen_server:cast(?MODULE, {unregister, WinId}).

get_all() ->
    gen_server:call(?MODULE, get_all).

init([]) ->
    {ok, #state{windows = []}}.

handle_call(get_all, _From, State) ->
    {reply, State#state.windows, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({register, WinId}, State) ->
    Windows = lists:usort([WinId | State#state.windows]),
    {noreply, State#state{windows = Windows}};
handle_cast({unregister, WinId}, State) ->
    Windows = lists:delete(WinId, State#state.windows),
    {noreply, State#state{windows = Windows}};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
