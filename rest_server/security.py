from shared import bcrypt, jwt
from flask_jwt import _default_jwt_payload_handler
from services.user_service import get_user_by_username


@jwt.authentication_handler
def authenticate(username, password):
    user = get_user_by_username(username)
    if user and bcrypt.check_password_hash(user.password, password):
        return user


@jwt.identity_handler
def identity(payload):
    username = payload['username']
    return get_user_by_username(username)


@jwt.jwt_payload_handler
def make_payload(user_identity):
    user_identity.id = None
    payload = _default_jwt_payload_handler(user_identity)
    payload['username'] = user_identity.username
    return payload


def config_jwt(jwt, app):
    jwt.init_app(app)
