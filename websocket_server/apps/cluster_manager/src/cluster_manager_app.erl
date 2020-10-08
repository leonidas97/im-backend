-module(cluster_manager_app).
-behaviour(application).
-export([start/2, stop/1]).


start(_StartType, _StartArgs) ->
    timer:sleep(500),
    cluster_manager_sup:start_link().


stop(_State) ->
    ok.


