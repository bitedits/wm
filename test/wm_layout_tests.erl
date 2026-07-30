-module(wm_layout_tests).
-include_lib("eunit/include/eunit.hrl").

stack_test() ->
    Windows = [1, 2, 3],
    ScreenGeom = {1024, 768},
    {ResWindows, ResScreen} = wm_layout:stack(Windows, ScreenGeom),
    ?assertEqual(Windows, ResWindows),
    ?assertEqual(ScreenGeom, ResScreen).
