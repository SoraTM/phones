-module(phone_dispatcher).
-export([start/0, rpc/2, loop/1, phone_list/1, stop_phones/1]).

start() ->
    Phones = [phone:enable() || _ <- lists:seq(1, 5)],
    Pid = spawn_link(?MODULE, loop, [Phones]),
    register(dispatcher, Pid).

rpc(Pid, Request) ->
    Pid ! {self(), Request},
    receive
        {Pid, Response} ->
        Response
    end.

phone_list(Pid) ->
    rpc(Pid, phone_list).

stop_phones(Pid) ->
    rpc(Pid, stop_phones).

loop(Phones) ->
    receive
        {From, phone_list} ->
            From ! {self(), Phones},
            loop(Phones);
        {From, stop_phones} -> 
            From ! {self(), [phone:stop(Pid) || Pid <- Phones]}
    end.
