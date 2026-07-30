-module(wm_x11).
-behaviour(gen_server).

-export([start_link/0, map_window/1, unmap_window/1, set_focus/1, create_window/6, move_resize/5]).
-export([set_border_color/2, set_border_width/2]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {port}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

map_window(WindowId) ->
    gen_server:cast(?MODULE, {command, io_lib:format("MAP_WINDOW ~w\n", [WindowId])}).

unmap_window(WindowId) ->
    gen_server:cast(?MODULE, {command, io_lib:format("UNMAP_WINDOW ~w\n", [WindowId])}).

set_focus(WindowId) ->
    gen_server:cast(?MODULE, {command, io_lib:format("SET_FOCUS ~w\n", [WindowId])}).

set_border_color(WindowId, HexColor) ->
    gen_server:cast(?MODULE, {command, io_lib:format("SET_BORDER_COLOR ~w ~s\n", [WindowId, HexColor])}).

set_border_width(WindowId, Width) ->
    gen_server:cast(?MODULE, {command, io_lib:format("SET_BORDER_WIDTH ~w ~w\n", [WindowId, Width])}).

create_window(W, X, Y, Width, Height, BorderWidth) ->
    gen_server:cast(?MODULE, {command, io_lib:format("CREATE_WINDOW ~w ~w ~w ~w ~w ~w\n", [W, X, Y, Width, Height, BorderWidth])}).

move_resize(W, X, Y, Width, Height) ->
    gen_server:cast(?MODULE, {command, io_lib:format("MOVE_RESIZE ~w ~w ~w ~w ~w\n", [W, X, Y, Width, Height])}).

init([]) ->
    process_flag(trap_exit, true),
    PrivDir = case code:priv_dir(wm) of
                  {error, bad_name} ->
                      filename:join([filename:dirname(code:which(?MODULE)), "..", "priv"]);
                  Dir -> Dir
              end,
    PortCmd = filename:join([PrivDir, "wm_x11"]),
    Port = open_port({spawn_executable, PortCmd}, [line, {line, 4096}, binary, exit_status]),
    {ok, #state{port = Port}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({command, CmdStr}, State) ->
    port_command(State#state.port, iolist_to_binary(CmdStr)),
    {noreply, State}.

handle_info({Port, {data, {eol, Line}}}, State = #state{port = Port}) ->
    Str = binary_to_list(Line),
    case string:tokens(Str, " ") of
        ["LOG" | Rest] ->
            io:format("[X11 LOG] ~s~n", [string:join(Rest, " ")]),
            {noreply, State};
        ["READY"] ->
            io:format("[X11] Port is ready.~n"),
            {noreply, State};
        ["EVENT" | EventParts] ->
            wm_event:dispatch(EventParts),
            {noreply, State};
        _ ->
            io:format("[X11 UNKNOWN] ~p~n", [Str]),
            {noreply, State}
    end;
handle_info({Port, {exit_status, Status}}, State = #state{port = Port}) ->
    io:format("[X11 EXIT] Port exited with status ~p~n", [Status]),
    {stop, {port_exited, Status}, State};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, State) ->
    case State#state.port of
        undefined -> ok;
        Port ->
            try port_command(Port, <<"SHUTDOWN\n">>) catch _:_ -> ok end,
            try port_close(Port) catch _:_ -> ok end
    end,
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
