-module(redis_manager_app).
-behaviour(application).
-export([start/2, stop/1]).


start(_StartType, _StartArgs) ->
    redis_manager_sup:start_link(),
    redis_worker_sup:start_link().


stop(_State) ->
    ok.
