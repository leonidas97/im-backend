-module(session).
-compile(export_all).


insert_user(Username, ConnectionId) ->
    ConnectionIdStr = utility:term_to_list(ConnectionId),
    redis_manager:command(write, [sadd, Username, ConnectionIdStr]).


remove_user(Username, ConnectionId) ->
    ConnectionIdStr = utility:term_to_list(ConnectionId),
    redis_manager:command(write, [srem, Username, ConnectionIdStr]).


get_user(Username) ->
    {ok, Results} = redis_manager:command(read, [smembers, Username]),
    lists:map(fun(Item) -> utility:list_to_term(binary_to_list(Item)) end, Results).


get_online_users(Users) ->
    Commands = lists:map(fun(User)-> [smembers, User] end, Users),
    Results = redis_manager:command_pipeline(read, Commands),
    Filtered = lists:map(fun({ok, Result})-> Result end, Results),
    Flattened = lists:flatten(Filtered),
    lists:map(fun(Item)-> utility:list_to_term(binary_to_list(Item)) end, Flattened). 


get_conversation_members(ConversationId) ->
    {ok, Members} = redis_manager:command(read, [smembers, ConversationId]),
    Members.


get_conversations_members(ConversationsIds) ->
    Commands = lists:map(fun(Id) -> [smembers, Id] end, ConversationsIds),
    Results = redis_manager:command_pipeline(read, Commands),
    Filtered = lists:map(fun({ok, Result})-> Result end, Results),
    Flattened = lists:flatten(Filtered),
    sets:to_list(sets:from_list(Flattened)).


get_conversation_member_details(ConversationId, Username) ->
    MemberIdList = binary_to_list(Username) ++ binary_to_list(ConversationId),
    MemberId = list_to_binary(MemberIdList),
    Commands = [[hget, MemberId, unread_msg_count], [hget, MemberId, last_msg_seen]],
    Results = redis_manager:command_pipeline(read, Commands),
    [{ok, UnreadMsgCount}, {ok, LastMsgSeen}] = Results,
    {UnreadMsgCount, LastMsgSeen}.


conversation_exists(ConversationId) ->
    {ok, Status} = redis_manager:command(read, [exists, ConversationId]),
    case Status of 
        <<"0">> -> false; 
        <<"1">> -> true 
    end.


insert_conversation(Conversation) ->
    ConversationId = maps:get(<<"conversation_id">>, Conversation),
    Participants = maps:get(<<"participants">>, Conversation),

    InsertConversationCommand = create_insert_conversation_command(ConversationId, Participants),
    InsertParticipantCommands = create_insert_participant_commands(ConversationId, Participants),
    Commands = InsertParticipantCommands ++ [InsertConversationCommand],
    redis_manager:command_pipeline(write, Commands).


join_conversation(ConversationId, ParticipantUsername) ->
    JoinCommand = [sadd, ConversationId, ParticipantUsername],
    Participant = #{
        <<"username">> => ParticipantUsername,
        <<"unread_msg_count">> => 0,
        <<"last_msg_seen">> => 0},
    
    InsertParticipantCommand = create_insert_participant_commands(ConversationId, [Participant]),
    Commands = InsertParticipantCommand ++ [JoinCommand],
    redis_manager:command_pipeline(write, Commands).


leave_conversation(ConversationId, ParticipantUsername) ->
    LeaveCommand = [srem, ConversationId, ParticipantUsername],
    RemoveParticipantCommand = [hdel, ConversationId, ParticipantUsername],
    Commands = [LeaveCommand, RemoveParticipantCommand],
    redis_manager:command_pipeline(write, Commands).


increase_unread_msg_count(ConversationId, Participants) ->
    Commands = lists:map(
        fun(Participant)->
            HKey = binary_to_list(Participant) ++ binary_to_list(ConversationId),
            [hincrby, HKey, unread_msg_count, 1]
        end, Participants),
    redis_manager:command_pipeline(write, Commands).


update_last_msg_seen(ConversationId, User, MessageTimestamp) ->
    HKey = binary_to_list(User) ++ binary_to_list(ConversationId),
    Commands = [[hset, HKey, unread_msg_count, 0], [hset, HKey, last_msg_seen, MessageTimestamp]],
    redis_manager:command_pipeline(write, Commands).


create_insert_conversation_command(ConversationId, Participants) ->
    ParticipantsUsernames = lists:map(
        fun(Participant)-> maps:get(<<"username">>, Participant) end,
        Participants),
    [sadd, ConversationId] ++ ParticipantsUsernames.
 

create_insert_participant_commands(ConversationId, Participants) ->
    lists:map(
        fun(PS) -> [
            hset, 
            binary_to_list(maps:get(<<"username">>, PS)) ++ binary_to_list(ConversationId),
            "unread_msg_count", maps:get(<<"unread_msg_count">>, PS),
            "last_msg_seen", maps:get(<<"last_msg_seen">>, PS)] 
        end, Participants).


remove_conversation(Conversation) -> {Conversation}.
