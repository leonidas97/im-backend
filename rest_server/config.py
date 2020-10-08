from datetime import timedelta

DATABASE = 'im_db'
HOST = 'mongo'
PORT = 27017

DEBUG = True
SECRET_KEY = 'super-secret'
JWT_AUTH_USERNAME_KEY = 'username'
JWT_AUTH_PASSWORD_KEY = 'password'
JWT_AUTH_HEADER_PREFIX = 'Bearer'
JWT_EXPIRATION_DELTA = timedelta(seconds=3600*24*365)
BCRYPT_LOG_ROUNDS = 12
