-module(websocket_manager).
-export([init/2, terminate/3]).
-export([websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req, _) ->
    Token = cowboy_req:binding(auth, Req),
    Username = utility:get_username_from_token(Token),
    State = maps:put(current_user, Username, #{}),
    {cowboy_websocket, Req, State, #{idle_timeout => 3600000}}.


websocket_init(State) ->
    process_flag(trap_exit, true),
    CurrentUser = maps:get(current_user, State),
    io:format("websocket connection established in ~p ~p ~n", [self(), CurrentUser]),
    
    NodeId = node(),
    WebsocketId = utility:create_websocket_id(),
    true = register(WebsocketId, self()),
    ConnectionId = {WebsocketId, NodeId},
    session:insert_user(maps:get(current_user, State), ConnectionId),

    PresenceEvent = #{
        current_user => CurrentUser,
        json_data => jsone:encode(#{
            state => <<"online">>,
            event_type=> <<"user_presence">>})},
    chat_server_sup:start_child(PresenceEvent),
    {ok, State#{connection_id => ConnectionId}}.


websocket_handle({text, JsonData}, State) ->    
    CurrentUser = maps:get(current_user, State),
    ConnectionId = maps:get(connection_id, State),
    Event = #{
        current_user => CurrentUser, 
        connection_id => ConnectionId,
        json_data => JsonData},
    chat_server_sup:start_child(Event),
    {ok, State}.


websocket_info({event, Data} , State) ->
    {[{text, Data}], State};


websocket_info(_Info, State) ->
    io:format("closing websocket connection in ~p~n", [self()]),
    {stop, State}.


terminate(Reason, _PartialReq, State) ->
    io:format("closing websocket connection with reason: ~p~n", [Reason]),
    ConnectionId = maps:get(connection_id, State),
    Username = maps:get(current_user, State),
    session:remove_user(Username, ConnectionId),
    
    Event = #{
        current_user => Username,
        json_data => jsone:encode(#{
            state => <<"offline">>,
            event_type=> <<"user_presence">>})},
    chat_server_sup:start_child(Event),
    ok.
