-module(wm_workspace).
-behaviour(gen_server).

-export([start_link/0, map_request/1, switch/1, get_active/0, unmap_notify/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {active = 1, win_to_ws = #{}}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

unmap_notify(WinId) ->
    gen_server:cast(?MODULE, {unmap_notify, WinId}).

map_request(WinId) ->
    gen_server:cast(?MODULE, {map_request, WinId}).

switch(WsId) ->
    gen_server:cast(?MODULE, {switch, WsId}).

get_active() ->
    gen_server:call(?MODULE, get_active).

init([]) ->
    {ok, #state{active = 1, win_to_ws = #{}}}.

handle_call(get_active, _From, State) ->
    {reply, State#state.active, State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({map_request, WinId}, State) ->
    NewMap = maps:put(WinId, State#state.active, State#state.win_to_ws),
    {noreply, State#state{win_to_ws = NewMap}};

handle_cast({unmap_notify, WinId}, State) ->
    NewMap = maps:remove(WinId, State#state.win_to_ws),
    {noreply, State#state{win_to_ws = NewMap}};

handle_cast({switch, WsId}, State) ->
    io:format("Switching to workspace ~p~n", [WsId]),
    %% In a real implementation we would unmap windows from old workspace
    %% and map windows from new workspace via wm_x11.
    {noreply, State#state{active = WsId}};

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
