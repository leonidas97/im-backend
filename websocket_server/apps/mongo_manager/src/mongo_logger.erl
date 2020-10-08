-module(mongo_logger).
-export([start_link/0, init/0, listen_loop/1, log/1]).

start_link() ->
    Pid = spawn_link(?MODULE, init, []),
    register(?MODULE, Pid),
    {ok, Pid}.

init() ->
    {ok, F} = file:open("mongo_logs.txt", [write]),
    listen_loop(F).

listen_loop(F) ->
    receive _ -> log(F) end,
    listen_loop(F).

log(F) ->
    Status = poolboy:status(mongo_pool),
    io:format(F, "rw:~p~n", [Status]).
