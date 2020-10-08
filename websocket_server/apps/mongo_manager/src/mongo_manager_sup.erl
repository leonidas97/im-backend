-module(mongo_manager_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).
-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1000,
        period => 1
    },

    LoggerSpec = #{
        id => mongo_logger,
        start => {mongo_logger, start_link, []}
    },

    WorkerSupSpec = #{
        id => mongo_worker_supervisor,
        start => {mongo_worker_sup, start_link, []},
        restart => permanent
    },

    ChildSpecs = [LoggerSpec, WorkerSupSpec],
    {ok, {SupFlags, ChildSpecs}}.
