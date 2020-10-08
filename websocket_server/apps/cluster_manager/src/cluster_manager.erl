-module(cluster_manager).
-export([start_link/0, init/0, loop/0, try_connect/2, try_register/2]).

%% Startuj klaster manager proces 
start_link() ->
    timer:sleep(10000),
    Pid = spawn_link(?MODULE, init, []),
    register(?MODULE, Pid),
    {ok, Pid}.

%% osluskuj EXIT signal za gasenje procesa
init() ->
    process_flag(trap_exit, true),
    loop().

%% Glavna petlja klaster menadzera
loop() ->
    Node = atom_to_list(node()),
    NodesRemoteData = get_nodes_from_redis(),
    NodesLocalData = lists:map(
        fun(NodeAtom) -> atom_to_list(NodeAtom) end, 
        nodes()),
    
    try_exit(Node),
    try_register(Node, NodesRemoteData),
    try_connect(NodesLocalData, NodesRemoteData),
    timer:sleep(1000*30),
    loop().

%% Dobavi registrovane cvorove
get_nodes_from_redis() -> 
    {ok, NodesRemoteDataBinary} = redis_manager:command(
        read, 
        ["smembers", "nodes"]),
    
    lists:map(
        fun(Node) -> binary:bin_to_list(Node) end, 
        NodesRemoteDataBinary).

%% Proveri da li ima 'EXIT' poruke u mailbox-u
%% ukoliko ima de-registruj se 
try_exit(Node) ->
    receive {'EXIT', _FromPid, Reason} -> 
        redis_manager:command(write, ["srem", "nodes", Node]), exit(Reason)
    after 0 -> ok
    end.

%% Registruj se ukoliko nisi registrovan
try_register(Node, RemoteNodes) ->
    IsRegistered = lists:any(
        fun(RemoteNode) -> string:equal(RemoteNode, Node) end, 
        RemoteNodes),

    case IsRegistered of
        true -> ok;
        false -> redis_manager:command(write, ["sadd", "nodes", Node])
    end.

%% Pronadji i povezi se sa cvorovima koji nisu moji susedi
try_connect(NodesLocalData, NodesRemoteData) ->
    NodeDiff = lists:filter(
        fun(RemoteNode) -> not lists:member(RemoteNode, NodesLocalData) end, 
        NodesRemoteData),

    lists:foreach(
        fun(RemoteNode) -> net_adm:ping(list_to_atom(RemoteNode)) end, 
        NodeDiff).
