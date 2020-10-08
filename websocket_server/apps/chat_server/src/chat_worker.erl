-module(chat_worker).
-compile(export_all).


start_link(Event) ->
    spawn_link(?MODULE, init, [Event]).


init(EventArg) ->
    JsonData = maps:get(json_data, EventArg),
    {ok, Data, _} = jsone:try_decode(JsonData),
    Event = maps:put(data, Data, EventArg),

    case binary_to_atom(maps:get(<<"event_type">>, Data)) of 
        my_conversations -> my_conversations(Event);
        create_conversation -> create_conversation(Event);
        conversation_request -> try_create_conversation_request(Event);
        process_conversation_request -> try_process_conversation_request(Event);
        leave_conversation -> leave_conversation(Event);
        new_message -> new_message(Event);
        message_seen -> message_seen(Event);
        user_presence -> user_presence(Event)
    end.


send(Connections, Event) ->
    lists:foreach(
        fun(Connection)-> 
            Connection ! {event, Event} 
        end, Connections).


deny(Event) ->
    Data = maps:get(data, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    ConnectionId = maps:get(connection_id, Event),
    DeniedEvent = #{
        status => <<"denied">>, 
        event_timestamp => EventTimestamp},
    send([ConnectionId], jsone:encode(DeniedEvent)).


my_conversations(Event) ->
    CurrentUser = maps:get(current_user, Event),
    ConnectionId = maps:get(connection_id, Event),
    Data = maps:get(data, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    
    CurrentUserDoc = mongo_manager:find_one(user, #{username => CurrentUser}),
    ConversationsIds = maps:get(<<"conversations">>, CurrentUserDoc),
    Conversations= mongo_manager:find(
        conversation, 
        #{conversation_id => #{'$in' => ConversationsIds}}),

    Results = lists:map(
        fun(Conversation) ->
            try_to_update_conversation_data(Conversation)
        end, Conversations),

    ReturnConversationsEvent = #{
        event_type => <<"my_conversations">>,
        event_timestamp => EventTimestamp, 
        conversations => Results},
    send([ConnectionId], jsone:encode(ReturnConversationsEvent)).


try_to_update_conversation_data(Conversation) ->
    ConversationId = maps:get(<<"conversation_id">>, Conversation),
    Members = session:get_conversation_members(ConversationId),
    UpdatedConversation = case Members of 
        [] -> Conversation; 
        _  -> update_conversation_data(ConversationId, Conversation, Members)
    end,
    CreatedAt = maps:get(<<"created_at">>, UpdatedConversation),
    Ret = maps:remove(<<"_id">>, UpdatedConversation),
    maps:put(<<"created_at">>, calendar:now_to_universal_time(CreatedAt), Ret).


update_conversation_data(ConversationId, Conversation, Members) ->
    Participants = lists:map(
        fun(Member) -> 
            {UnreadMsgCount, LastMsgSeen} = session:get_conversation_member_details(ConversationId, Member),
            OutdatedParticipants = maps:get(<<"participants">>, Conversation),
            UpdatedParticipantList = lists:filtermap(
                fun(Participant) ->
                    case maps:get(<<"username">>, Participant) of
                        Member -> {true, Participant#{
                            <<"last_msg_seen">> => LastMsgSeen,
                            <<"unread_msg_count">> => UnreadMsgCount}};
                        _ -> false
                    end
                end, OutdatedParticipants),
            lists:nth(1, UpdatedParticipantList) 
        end, Members),
    Conversation#{<<"participants">> => Participants}.
 

create_conversation(Event) ->
    Data = maps:get(data, Event),
    CurrentUser = maps:get(current_user, Event),
    ConnectionId = maps:get(connection_id, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    CreatedAt = erlang:timestamp(),
    ConversationId = utility:create_conversation_id(),

    ConvToSave = #{
        conversation_id => ConversationId,
        event_timestamp => EventTimestamp,
        name => maps:get(<<"name">>, Data),
        created_at => CreatedAt,
        participants => [#{
            username => CurrentUser,
            unread_msg_count => 0, 
            last_msg_seen => 0}]},
    
    spawn(fun() -> 
        mongo_manager:insert(conversation, ConvToSave),
        mongo_manager:update(
            user, 
            #{username => CurrentUser},
            #{'$push' => #{conversations => ConversationId}}) end),
    
    %% napravi response event
    ResponseEvent = #{
        event_type => <<"conversation_created">>,
        event_timestamp => EventTimestamp,
        data => ConvToSave#{
            created_at => 
            calendar:now_to_universal_time(CreatedAt)}},
    send([ConnectionId], jsone:encode(ResponseEvent)).


leave_conversation(Event) ->
    Data = maps:get(data, Event),
    CurrentUser = maps:get(current_user, Event),
    ConnectionId = maps:get(connection_id, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    ConversationId = maps:get(<<"conversation_id">>, Data),

    % azuriraj redis i bazu 
    session:leave_conversation(ConversationId, CurrentUser),
    spawn(fun() -> 
        mongo_manager:update(
            conversation, 
            #{conversation_id => ConversationId}, 
            #{<<"$pull">> => #{<<"participants">> => 
            #{<<"username">> => CurrentUser}}}),

        mongo_manager:update(
            user,
            #{username => CurrentUser},
            #{'$pull' => #{conversations => ConversationId}}) end),
    
    % napravi response event
    ResponseEvent = #{
        event_type => <<"user_left_conversation">>,
        data => ConversationId,
        user => CurrentUser,
        event_timestamp => EventTimestamp},

    % posalji svim aktivnim ucesnicima
    Members = session:get_conversation_members(ConversationId),
    OnlineMembers = session:get_online_users(Members),
    send(OnlineMembers, jsone:encode(ResponseEvent)),
    send([ConnectionId], jsone:encode(ResponseEvent)).


try_open_conversation(ConversationId) ->
    % ako konverzacija nije u sesiji -> ubaci je
    case session:conversation_exists(ConversationId) of 
        false -> 
            ConversationDoc = mongo_manager:find_one(
                conversation, 
                #{conversation_id => ConversationId}), 
            session:insert_conversation(ConversationDoc);
        true -> ok
    end.


try_create_conversation_request(Event) ->
    Data = maps:get(data, Event),
    ConversationId = maps:get(<<"conversation_id">>, Data),
    Recipient = maps:get(<<"recipient">>, Data),
    
    case conversation_request_invalid(ConversationId, Recipient) of 
        false -> create_conversation_request(Event);
        true -> deny(Event)
    end.


create_conversation_request(Event) ->
    Data = maps:get(data, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    ConversationId = maps:get(<<"conversation_id">>, Data),
    Recipient = maps:get(<<"recipient">>, Data),
    Sender = maps:get(current_user, Event),
    RequestId = utility:create_conversation_req_id(),
    CreatedAtTimestamp = erlang:timestamp(),
    CreatedAt = calendar:now_to_universal_time(CreatedAtTimestamp),
    Status = <<"new">>,

    ConversationRequest = #{
        request_id => RequestId,
        event_timestamp => EventTimestamp,
        conversation_id => ConversationId,
        created_at => CreatedAt,
        sender => Sender, 
        recipient => Recipient,
        status => Status},

    ConversationRequestDoc = maps:put(
        created_at, 
        CreatedAtTimestamp, 
        ConversationRequest),
    
    spawn(fun()-> 
        mongo_manager:insert(
            conversation_request, 
            ConversationRequestDoc) end),

    ConversationRequestEvent = maps:put(
        event_type, 
        <<"conversation_request">>, 
        ConversationRequest),
    ConnectionIds = session:get_online_users([Sender, Recipient]),
    send(ConnectionIds, jsone:encode(ConversationRequestEvent)).


conversation_request_invalid(ConversationId, Recipient) ->
    Participant = mongo_manager:find_one(conversation, #{
        conversation_id => ConversationId,
        'participants.username' => Recipient}),
    
    NewConversationRequest = mongo_manager:find_one(conversation_request, #{
        conversation_id => ConversationId,
        recipient => Recipient, 
        status => <<"new">>}),
    
    case {Participant, NewConversationRequest} of 
        {undefined, undefined} -> false;
        {_, _} -> true 
    end.


try_process_conversation_request(Event) ->
    Data = maps:get(data, Event),
    RequestId = maps:get(<<"request_id">>, Data),
    RequestState = maps:get(<<"state">>, Data),
    RequestDoc = mongo_manager:find_one(
        conversation_request, 
        #{request_id => RequestId}),
    
    case {RequestDoc, RequestState} of 
        {undefined, _} -> deny(Event);
        {_, <<"deny">>} -> deny_conversation_request(Data, RequestDoc);
        {_, <<"accept">>} -> accept_conversation_request(Data, RequestDoc)
    end. 


accept_conversation_request(Data, ConversationRequest) ->
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    CurrentUser = maps:get(<<"recipient">>, ConversationRequest),
    RequestId = maps:get(<<"request_id">>, ConversationRequest),
    ConversationId = maps:get(<<"conversation_id">>, ConversationRequest),

    spawn(fun()-> 
        mongo_manager:update(conversation_request, 
            #{request_id => RequestId}, 
            #{'$set' => #{status => <<"accepted">>}}),
        
        mongo_manager:update(conversation,
            #{conversation_id => ConversationId},
            #{'$push' => #{participants => #{
                username => CurrentUser,
                unread_msg_count => 0, 
                last_msg_seen => 0}}}),
        
        mongo_manager:update(
            user, 
            #{username => CurrentUser},
            #{'$push' => #{conversations => ConversationId}}) end),

    ResponseEvent = #{
        event_timestamp => EventTimestamp,
        event_type => <<"user_joined_conversation">>,
        user => CurrentUser,
        request_id => RequestId,
        conversation_id => ConversationId},

    try_open_conversation(ConversationId),
    session:join_conversation(ConversationId, CurrentUser),
    Members = session:get_conversation_members(ConversationId),
    OnlineMembers = session:get_online_users(Members),
    send(OnlineMembers, jsone:encode(ResponseEvent)).


deny_conversation_request(Data, ConversationRequest) ->
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    RequestId = maps:get(<<"request_id">>, ConversationRequest),
    ConversationId = maps:get(<<"conversation_id">>, ConversationRequest),
    Recipient = maps:get(<<"recipient">>, ConversationRequest),

    spawn(fun()-> mongo_manager:update(
        conversation_request, 
        #{request_id => RequestId}, 
        #{'$set' => #{status => <<"deny">>}}) 
    end),

    ResponseEvent = #{
        event_timestamp => EventTimestamp,
        event_type => <<"user_declined_conversation_request">>,
        user => Recipient,
        request_id => RequestId,
        conversation_id => ConversationId},

    try_open_conversation(ConversationId),
    Members = session:get_conversation_members(ConversationId),
    OnlineMembers = session:get_online_users(Members),
    send(OnlineMembers, jsone:encode(ResponseEvent)).


new_message(Event) ->
    Data = maps:get(data, Event),
    CurrentUser = maps:get(current_user, Event),
    EventTimestamp = maps:get(<<"event_timestamp">>, Data),
    ConversationId = maps:get(<<"conversation_id">>, Data),
    Text = maps:get(<<"text">>, Data),
    CreatedAt = erlang:timestamp(),
    MessageTimestamp = utility:create_message_timestamp(),

    MessageDocument = #{
        event_type => <<"server_recieved_message">>,
        event_timestamp => EventTimestamp,
        conversation_id => ConversationId,
        message_timestamp => MessageTimestamp,
        created_at => CreatedAt,
        sender => CurrentUser,
        text => Text},
    % delegate inserting to async mongo workers
    spawn(fun()->mongo_manager:insert(
        message, 
        MessageDocument)
    end),
    
    try_open_conversation(ConversationId),
    MessageEvent = MessageDocument#{
        created_at => calendar:now_to_universal_time(CreatedAt)},
    SenderConnectionIds = session:get_user(CurrentUser),
    send(SenderConnectionIds, jsone:encode(MessageEvent)),
    send_message_to_others(MessageEvent),
    ok.


send_message_to_others(PartialMessageEvent) ->
    MessageEvent = PartialMessageEvent#{event_type => <<"new_message">>},
    CurrentUser = maps:get(sender, MessageEvent),
    ConversationId = maps:get(conversation_id, MessageEvent),

    Members = session:get_conversation_members(ConversationId),
    Recievers = lists:delete(CurrentUser, Members), 
    session:increase_unread_msg_count(ConversationId, Recievers),
    RecieversConnectionIds = session:get_online_users(Recievers),
    send(RecieversConnectionIds, jsone:encode(MessageEvent)).


message_seen(Event) ->
    Data = maps:get(data, Event),
    CurrentUser = maps:get(current_user, Event),
    ConversationId = maps:get(<<"conversation_id">>, Data),
    MessageTimestamp = maps:get(<<"message_timestamp">>, Data),

    SeenEvent = #{
        event_type => <<"message_seen">>,
        user => CurrentUser, 
        conversation_id => ConversationId,
        message_timestamp => MessageTimestamp},
    
    try_open_conversation(ConversationId),
    Members = session:get_conversation_members(ConversationId),
    session:update_last_msg_seen(ConversationId, CurrentUser, MessageTimestamp),
    RecieversConnectionIds = session:get_online_users(Members),
    send(RecieversConnectionIds, jsone:encode(SeenEvent)).


user_presence(Event) ->
    Data = maps:get(data, Event),
    CurrentUser = maps:get(current_user, Event),
    State = maps:get(<<"state">>, Data),

    UserDocument = mongo_manager:find_one(user, #{username => CurrentUser}),
    ConversationsIds = maps:get(<<"conversations">>, UserDocument),
    PresenceEvent = #{
        event_type => <<"presence">>,
        user => CurrentUser,
        state => State},

    Members = session:get_conversations_members(ConversationsIds),
    OnlineMembersConnectionIds = session:get_online_users(Members),
    send(OnlineMembersConnectionIds, jsone:encode(PresenceEvent)).
