FROM python:slim-buster
WORKDIR /usr/src/app
COPY . /usr/src/app
RUN pip3 install -r requirments.txt
RUN export FLASK_APP=app.py
EXPOSE 5000
CMD flask run --host=0.0.0.0
