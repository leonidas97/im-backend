-module(mongo_worker_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).
-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    {ok, Pools} = application:get_env(mongo_manager, pools),
    PoolSpecs = lists:map(
        fun({Name, SizeArgs, WorkerArgs}) ->
            PoolArgs = [{name, {local, Name}}, {worker_module, mongo_connection_keeper}],
            poolboy:child_spec(Name, PoolArgs++SizeArgs, WorkerArgs) 
        end, Pools),
    {ok, {{one_for_one, 1000, 1}, PoolSpecs}}.
