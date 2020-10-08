from models.documents import User
from exceptions.exceptions import UsernameTaken
from shared import bcrypt
from flask_jwt import current_identity


def get_current_user():
    return current_identity


def create_user(user_data):
    if get_user_by_username(user_data['username']):
        raise UsernameTaken()
    else:
        password = bcrypt.generate_password_hash(user_data['password'])
        user = User(username=user_data['username'], password=password).save()
        return user 


def get_user_by_username(username):
    return User.objects(username=username).first()

