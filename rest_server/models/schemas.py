from marshmallow import Schema, fields


class UserInputSchema(Schema):
    username = fields.Str(required=True)
    password = fields.Str(required=True)


class UserOutputSchema(Schema):
    username = fields.Str()
    conversations = fields.List(fields.Str)


class ParticipantOutputSchema(Schema):
    username = fields.Str()
    unread_msg_count = fields.Int()
    last_msg_received = fields.Int()
    last_msg_seen = fields.Int()


class ConversationOutputSchema(Schema):
    conversation_id = fields.Str()
    name = fields.Str()
    created_at = fields.DateTime()
    last_msg_timestamp = fields.Int()
    participants = fields.List(fields.Nested(ParticipantOutputSchema))


class ConversationRequestOutputSchema(Schema):
    request_id = fields.Str()
    conversation_id = fields.Str()
    created_at = fields.DateTime()
    sender = fields.Str()
    recipient = fields.Str()


class MessageOutputSchema(Schema):
    timestamp = fields.Int()
    created_at = fields.DateTime()
    sender = fields.Str()
    conversation_id = fields.Str()
    text = fields.Str()
