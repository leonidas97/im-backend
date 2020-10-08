from werkzeug.exceptions import HTTPException


class JsonHttpException(HTTPException):
    code = None
    description = None


class UsernameTaken(JsonHttpException):
    code = 400
    description = 'Username is taken.'


class NotFound(JsonHttpException):
    code = 404
    description = 'Resource not found'


class Forbidden(JsonHttpException):
    code = 403
    description = 'Forbidden'


class ValidationFailure(JsonHttpException):
    code = 400
    description = 'Your request failed to meet validation/bussines rules'
