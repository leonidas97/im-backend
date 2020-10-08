-module(redis_manager).
-behaviour(gen_server).
-export([start_link/0, get_pool/1, command/2, command_pipeline/2]).
-export([init/1, handle_call/3, handle_cast/2]).


%%%%%%%%%%%%%%%%%
%%% ClientAPI %%%
%%%%%%%%%%%%%%%%%

command(Poolgroup, Params) ->
    Poolname = get_pool(Poolgroup),
    GenServerCall = fun(Worker) -> eredis:q(Worker, Params) end,
    Timeout = 10000,
    poolboy:transaction(
        Poolname,
        GenServerCall,
        Timeout).


command_pipeline(Poolgroup, Params) ->
    Poolname = get_pool(Poolgroup),
    GenServerCall = fun(Worker) -> eredis:qp(Worker, Params) end,
    Timeout = 10000,
    poolboy:transaction(
        Poolname,
        GenServerCall,
        Timeout).


%%%%%%%%%%%%%%%%%%%%
%%% GenServerAPI %%%
%%%%%%%%%%%%%%%%%%%%

start_link() ->
    gen_server:start_link({local, redis_manager}, ?MODULE, [], []).


get_pool(Poolgroup) ->
    gen_server:call(redis_manager, {get, Poolgroup}).


init(_Args) ->
    {ok, Poolgroups} = application:get_env(redis_manager, pool_groups),
    {ok, Poolgroups}.


handle_call({get, Poolgroup}, _From, State) ->
    PoolgroupList = maps:get(Poolgroup, State),
    Pool = lists:nth(rand:uniform(length(PoolgroupList)), PoolgroupList),
    {reply, Pool, State}.


handle_cast(_Request, State) ->
    {noreply, State}.
