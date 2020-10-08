# Instant Messaging app

Scalable WebSocket chat application backend built with HAProxy, Erlang, Python, Redis and MongoDB.

## Development mode:
- ### Requirments:
  - Docker and Docker-Compose
  - Erlang/OTP 23
  - Rebar3 built tool
  - JMeter for tests
  
- ### Instructions:
  - Docker init
  ``` 
    cd /rest_server
    docker build image -t rest .
    docker-compose up
  ```
  - Insert test users using mongo shell
  ``` 
    load("/mongo_config/mongo_init.js");
  ```
  - Start one WebSocket server node
  ```
    cd ../websocket_server
    rebar3 shell --name node1@127.0.0.1
  ```
  - Start tests from JMeter GUI or command-line


## Deployment mode:
- ### Requirments:
  - Docker
  - JMeter for tests
   
- ### Instructions:
  - Update hostname configs for redis and mongo managers in /websocket_server/apps
  - Rebuild docker images 
  ```
    docker image build -t ws . // in /websocket_server
    docker image build -t rest . // in /rest_server
  ```
  - Update JMeter samplers ports to {IP_ADDRESS}:80
  - Initialize docker swarm and start containters
  ```
    docker swarm init --advertise-addr {IP_ADDRESS}
    docker stack deploy --compose-file docker-stack.yml im
  ```
  - Insert test data using mongo shell
  ``` 
    load("/mongo_config/mongo_init.js");
  ```
  - Start tests from JMeter GUI or command-line tool
  
