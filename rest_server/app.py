from flask import Flask
from mongoengine import connect
from controllers.user_controller import users
from controllers.conversation_controller import conversations
from security import config_jwt
from shared import jwt

app = Flask(__name__)
app.register_blueprint(users)
app.register_blueprint(conversations)
app.config.from_pyfile('config.py')
connect(app.config['DATABASE'], host=app.config['HOST'], port=app.config['PORT'])
config_jwt(jwt, app)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
