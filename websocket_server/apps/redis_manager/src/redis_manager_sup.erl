-module(redis_manager_sup).
-behaviour(supervisor).
-export([start_link/0]).
-export([init/1]).
-define(SERVER, ?MODULE).


start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).


init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 1
    },

    LoggerSpec = #{
        id => redis_logger,
        start => {redis_logger, start_link, []}
    },

    ManagerSpec = #{
        id => redis_manager,
        start => {redis_manager, start_link, []}
    },

    ChildSpec = [LoggerSpec, ManagerSpec],
    {ok, {SupFlags, ChildSpec}}.
