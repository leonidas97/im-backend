-module(chat_server_app).
-behaviour(application).
-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/websocket/:auth", websocket_manager, []}]}
    ]),

    {ok, _} = cowboy:start_clear(
        my_http_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    chat_server_sup:start_link().

stop(_State) ->
    ok.
