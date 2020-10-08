from mongoengine import Document, \
    DateTimeField, \
    StringField, \
    ListField, \
    IntField, \
    EmbeddedDocument, \
    EmbeddedDocumentField


class User(Document):
    username = StringField()
    password = StringField()
    conversations = ListField(StringField())


class Participant(EmbeddedDocument):
    username = StringField()
    unread_msg_count = IntField()
    last_msg_seen = IntField()


class Conversation(Document):
    conversation_id = StringField()
    name = StringField()
    created_at = DateTimeField()
    last_msg_timestamp = IntField()
    participants = ListField(EmbeddedDocumentField(Participant))


class ConversationRequest(Document):
    request_id = StringField()
    conversation_id = StringField()
    created_at = DateTimeField()
    sender = StringField()
    recipient = StringField()
    status = StringField()  # new, approved, declined


class Message(Document):
    timestamp = IntField()
    created_at = DateTimeField()
    sender = StringField()
    conversation_id = StringField()
    text = StringField()
