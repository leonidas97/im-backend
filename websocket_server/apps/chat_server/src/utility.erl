-module(utility).
-compile(export_all).


get_username_from_token(Token) ->
    {ok, Data} = jwerl:verify(Token, hs256, jwt_key()),
    maps:get(username, Data).


jwt_key() ->
    {ok, Key} = application:get_env(chat_server, jwt_key),
    Key.


term_to_list(Term) ->
    List = io_lib:format("~p", [Term]),
    lists:flatten(List).


list_to_term(List) ->
    {ok, Tokens, _} = erl_scan:string(List ++ "."),
    {ok, Term} = erl_parse:parse_term(Tokens),
    Term.


create_websocket_id() ->
    Timestamp = erlang:timestamp(),
    Id = erlang:phash2(Timestamp),
    AtomId = list_to_atom(integer_to_list(Id)),
    case whereis(AtomId) of 
        undefined -> AtomId;
        _ -> create_websocket_id()
    end.


create_conversation_id() ->
    Timestamp = erlang:timestamp(),
    Id = erlang:phash2(Timestamp),
    Ret = mongo_manager:find_one(<<"conversation">>, 
        #{<<"conversation_id">> => list_to_binary(integer_to_list(Id))}), 
    
    case Ret of 
        undefined -> list_to_binary(integer_to_list(Id));
        Ret -> create_conversation_id()
    end.


create_conversation_req_id() ->
    Timestamp = erlang:timestamp(),
    Id = erlang:phash2(Timestamp),
    Ret = mongo_manager:find_one(
        <<"conversation_request">>, 
        #{<<"request_id">> => list_to_binary(integer_to_list(Id))}), 
    
    case Ret of 
        undefined -> list_to_binary(integer_to_list(Id));
        Ret -> create_conversation_req_id()
    end.


create_message_timestamp() ->
    Timestamp = os:system_time(nano_seconds),
    list_to_binary(integer_to_list(Timestamp)).
