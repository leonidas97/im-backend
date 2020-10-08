from flask import Blueprint, request, jsonify
from flask_jwt import jwt_required
import services.user_service as service
import services.conversation_service as conversation_service
from models.schemas import UserInputSchema, \
    UserOutputSchema, \
    ConversationOutputSchema, \
    ConversationRequestOutputSchema

users = Blueprint('users', __name__, url_prefix='/users')


@users.route('', methods=['POST'])
def create_user():
    user_data = UserInputSchema().load(request.get_json(force=True))
    return jsonify(UserOutputSchema().dump(service.create_user(user_data)))


@users.route('/my_conversations', methods=['GET'])
@jwt_required()
def my_conversations():
    conversations_data = ConversationOutputSchema().dump(conversation_service.get_my_conversations(), many=True)
    return jsonify(conversations_data)


@users.route('/my_conversation_requests', methods=['GET'])
@jwt_required()
def my_conversation_requests():
    requests_data = ConversationRequestOutputSchema().dump(conversation_service.get_my_conversation_requests(), many=True)
    return jsonify(requests_data)
