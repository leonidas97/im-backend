-module(mongo_manager).
-export([
    insert/2,
    delete/2,
    find/2,
    find_one/2,
    update/3,
    ensure_index/2
]).


insert(Collection, Documents) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        mc_worker_api:insert(Connection, Collection, Documents)
    end).


delete(Collection, Selector) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        mc_worker_api:delete(Connection, Collection, Selector)
    end).


find(Collection, Selector) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        {ok, Cursor} = mc_worker_api:find(Connection, Collection, Selector),
        mc_cursor:rest(Cursor)
    end).


find_one(Collection, Selector) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        mc_worker_api:find_one(Connection, Collection, Selector)
    end).


update(Collection, Selector, Command) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        mc_worker_api:update(Connection, Collection, Selector, Command)
    end).


ensure_index(Collection, Selector) ->
    poolboy:transaction(mongo_pool, fun(ConnectionKeeper) ->
        mongo_logger ! log,
        Connection = gen_server:call(ConnectionKeeper, get_connection),
        mc_worker_api:ensure_index(Connection, Collection, Selector)
    end).
