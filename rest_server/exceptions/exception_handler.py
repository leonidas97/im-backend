from flask import Blueprint, json
from exceptions.exceptions import ValidationFailure
from werkzeug.exceptions import HTTPException
from marshmallow.exceptions import ValidationError

handler = Blueprint('ExceptionHandler', __name__)


@handler.app_errorhandler(HTTPException)
def handle(ex):
    response = ex.get_response()
    response.data = json.dumps({
        "code": ex.code,
        "description": ex.description,
    })
    response.content_type = "application/json"
    return response


@handler.app_errorhandler(ValidationError)
def handle_validation(ex):
    ex = ValidationFailure()
    return handle(ex)
