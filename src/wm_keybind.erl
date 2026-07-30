-module(wm_keybind).
-behaviour(gen_server).

-export([start_link/0, key_press/3]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

key_press(WinId, KeyCode, KeyState) ->
    gen_server:cast(?MODULE, {key_press, WinId, KeyCode, KeyState}).

init([]) ->
    {ok, #{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({key_press, _WinId, KeySymStr, KeyState}, State) ->
    Mods = parse_modifiers(KeyState),
    check_and_execute(Mods, KeySymStr),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

parse_modifiers(StateMask) ->
    Mods = [],
    Mods1 = if StateMask band 1 =/= 0 -> ["Shift" | Mods]; true -> Mods end,
    Mods2 = if StateMask band 4 =/= 0 -> ["Control" | Mods1]; true -> Mods1 end,
    Mods3 = if StateMask band 8 =/= 0 -> ["Mod1" | Mods2]; true -> Mods2 end,
    Mods4 = if StateMask band 64 =/= 0 -> ["Mod4" | Mods3]; true -> Mods3 end,
    Mods4.

check_and_execute(Mods, KeySymStr) ->
    Config = wm_config:get_config(),
    case lists:keyfind(keybinds, 1, Config) of
        {keybinds, Binds} ->
            match_binds(Binds, Mods, KeySymStr);
        false -> ok
    end.

match_binds([], _Mods, _KeySymStr) -> ok;
match_binds([{{ReqMod, ReqSym}, Cmd} | Rest], Mods, KeySymStr) ->
    %% Right now we support exactly 1 modifier + 1 key combo (e.g. "Mod1", "Return")
    case lists:member(ReqMod, Mods) andalso (ReqSym =:= KeySymStr) of
        true ->
            io:format("Executing keybind: ~s~n", [Cmd]),
            os:cmd("DISPLAY=:1 " ++ Cmd ++ " &");
        false ->
            match_binds(Rest, Mods, KeySymStr)
    end.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
