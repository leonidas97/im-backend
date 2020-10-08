-module(mongo_connection_keeper).
-behaviour(gen_server).
-export([
    start_link/1, 
    init/1, 
    connect/1,
    handle_info/2, 
    handle_cast/2,
    handle_call/3, 
    terminate/2, 
    code_change/3
]).


%%%%%%%%%%%%%%%%%%%%
%%% GenServerAPI %%%
%%%%%%%%%%%%%%%%%%%%

start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).


init(Args) ->
    erlang:send_after(1000, self(), connect),
    {ok, #{args => Args, connection => nil}}.


handle_call(get_connection, _From, State) ->
    {reply, maps:get(connection, State), State}.


handle_cast(_Request, State) ->
    {noreply, State}.


handle_info(connect, State) ->
    erlang:send_after(10000, self(), connect),
    NewState = case maps:get(connection, State) of 
        nil -> 
            Connection = connect(maps:get(args, State)),
            maps:put(connection, Connection, State);
        _ -> State
    end,
    {noreply, NewState}.


connect(Args) ->
    case mc_worker_api:connect(Args) of 
        {ok, Pid} -> Pid;
        _ -> nil
    end.


terminate(_Reason, State) ->
    Connection = maps:get(connection, State),
    mc_worker_api:disconnect(Connection).


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

