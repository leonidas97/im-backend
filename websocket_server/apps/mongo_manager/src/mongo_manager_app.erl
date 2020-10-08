-module(mongo_manager_app).
-behaviour(application).
-export([start/2, stop/1]).


start(_StartType, _StartArgs) ->
    mongo_manager_sup:start_link().


stop(_State) ->
    ok.
