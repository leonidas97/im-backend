-module(cluster_manager_sup).
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

    ChildSpecs = [#{
        id => cluster_manager,
        start => {cluster_manager, start_link, []}
    }],
    
    {ok, {SupFlags, ChildSpecs}}.
