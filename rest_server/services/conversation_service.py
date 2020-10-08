from flask_jwt import current_identity
from models.documents import User, ConversationRequest, Conversation, Message
from exceptions.exceptions import Forbidden, NotFound


def get_current_user():
    return current_identity


def get_current_user_obj():
    username = get_current_user().username
    return User.objects(username=username).first()


def get_conversation_obj(conversation_id):
    conversation = Conversation.objects(conversation_id=conversation_id).first()
    if Conversation is not None:
        return conversation
    raise NotFound()


def get_my_conversations():
    username = get_current_user().username
    user = User.objects(username=username).first()
    conversation_ids = user.conversations
    return Conversation\
        .objects(conversation_id__in=conversation_ids)\
        .order_by('-timestamp')\
        .select_related()


def get_my_conversation_requests():
    username = get_current_user().username
    return ConversationRequest\
        .objects(recipient=username, status='new')\
        .order_by('-created_at')\
        .select_related()


def get_last_n_messages(conversation_id, n):
    user = get_current_user_obj()
    if conversation_id in user.conversations:
        conversation = get_conversation_obj(conversation_id)
        return Message\
            .objects(conversation_id=conversation.conversation_id)\
            .order_by('-timestamp')\
            .limit(n)\
            .select_related()
    else:
        raise Forbidden()
