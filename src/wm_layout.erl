-module(wm_layout).
-export([stack/2]).

%% Pure function for stacking layout
%% Since it's stacking, the user controls windows primarily.
%% But if we need to auto-arrange (e.g. tile or cascade), it goes here.
stack(Windows, ScreenGeom) ->
    %% For stacking, maybe just cascade new windows slightly offset from top-left.
    %% This is a stub for potential automatic layout.
    {Windows, ScreenGeom}.
