-module(chat_server_sup).
-behaviour(supervisor).
-export([start_link/0, start_child/1]).
-export([init/1]).


start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).


start_child(Event) ->
    supervisor:start_child(?MODULE, [Event]).


init([]) ->
    SupFlags = #{
        strategy => simple_one_for_one,         
        intensity => 0,
        period => 1
    },

    ChildSpec = [#{
        id => chat_worker,
        start => {chat_worker, start_link, []},
        restart => temporary,
        type => worker
    }],

    {ok, {SupFlags, ChildSpec}}.
