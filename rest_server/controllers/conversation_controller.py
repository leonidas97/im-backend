from flask import Blueprint, jsonify
from flask_jwt import jwt_required
from models.schemas import MessageOutputSchema
import services.conversation_service as conversation_service

conversations = Blueprint('conversations', __name__, url_prefix='/conversations')


@conversations.route('<string:conv_id>/last/<int:n>', methods=['GET'])
@jwt_required()
def get_last_n_messages(conv_id, n):
    messages = conversation_service.get_last_n_messages(conv_id, n)
    messages_data = MessageOutputSchema().dump(messages, many=True)
    return jsonify(messages_data)
