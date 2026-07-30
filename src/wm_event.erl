-module(wm_event).
-behaviour(gen_server).

-record(state, {focused_window = undefined}).

-export([start_link/0, dispatch/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

dispatch(EventTokens) ->
    gen_server:cast(?MODULE, {event, EventTokens}).

init([]) ->
    {ok, #state{}}.

get_color(Key, Default) ->
    case wm_config:get_config() of
        undefined -> Default;
        Config ->
            case lists:keyfind(colors, 1, Config) of
                {colors, Colors} ->
                    case lists:keyfind(Key, 1, Colors) of
                        {Key, Value} -> Value;
                        false -> Default
                    end;
                false -> Default
            end
    end.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({event, ["MapRequest", WinStr]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    io:format("DEBUG: Handling MapRequest for window ~p~n", [WinId]),
    wm_windows:register_window(WinId),
    wm_workspace:map_request(WinId),
    wm_x11:set_border_width(WinId, 3),
    wm_x11:set_border_color(WinId, get_color(inactive_border, "#333333")),
    wm_x11:map_window(WinId),
    {noreply, State};

handle_cast({event, ["UnmapNotify", WinStr]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    wm_windows:unregister_window(WinId),
    wm_workspace:unmap_notify(WinId),
    NewState = if State#state.focused_window =:= WinId -> State#state{focused_window = undefined};
                  true -> State end,
    {noreply, NewState};

handle_cast({event, ["DestroyNotify", WinStr]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    wm_windows:unregister_window(WinId),
    wm_workspace:unmap_notify(WinId),
    NewState = if State#state.focused_window =:= WinId -> State#state{focused_window = undefined};
                  true -> State end,
    {noreply, NewState};

handle_cast({event, ["EnterNotify", WinStr]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    
    %% Unset old focus color if exists
    OldFocused = State#state.focused_window,
    if OldFocused =/= undefined andalso OldFocused =/= WinId ->
        wm_x11:set_border_color(OldFocused, get_color(inactive_border, "#333333"));
    true -> ok end,
    
    %% Set new focus color
    wm_x11:set_border_color(WinId, get_color(active_border, "#00FFCC")),
    wm_x11:set_focus(WinId),
    {noreply, State#state{focused_window = WinId}};

handle_cast({event, ["ConfigureRequest", WinStr, XStr, YStr, WStr, HStr, _BWStr]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    X = list_to_integer(XStr),
    Y = list_to_integer(YStr),
    W = list_to_integer(WStr),
    H = list_to_integer(HStr),
    wm_x11:move_resize(WinId, X, Y, W, H),
    {noreply, State};

handle_cast({event, ["KeyPress", WinStr, KeySymStr, KeyState]}, State) ->
    WinId = list_to_integer(WinStr, 16),
    wm_keybind:key_press(WinId, KeySymStr, list_to_integer(KeyState)),
    {noreply, State};

handle_cast({event, Event}, State) ->
    io:format("Unhandled X11 Event: ~p~n", [Event]),
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
