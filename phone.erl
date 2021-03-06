-module(phone).
-export([enable/0, rpc/2, idle/0, call/1, stop/1]).

enable() -> spawn(?MODULE, idle, []).

rpc(Pid, Request) ->
    Pid ! {self(), Request},
    receive
        {Pid, Response} ->
            Response
    end.

call(Pid) ->
    Pid ! {self(), connect_request}.

stop(Pid) ->
    rpc(Pid, stop).

idle() ->
    receive
        {From, connect_request} -> 
            io:format("Call request~n"),
            From ! {self(), connect_allowed},
            connected();
        {From, stop} ->
            disable(From);
        {From, _} ->
            From ! {self(), free_line},
            idle();
        M -> io:format("Shit happened idle ~p~n", [M])
    after rand:uniform(10000)
          -> test_call()
    end.

connecting(Client) ->
    self() ! call(Client),
    receive
        {From, connect_allowed} ->
            io:format("Message sended allowed ~n"),
            From ! {self(), {message, "Hello"}},
            connected();
        {From, connect_request} -> 
            io:format("Message sended connect req when busy ~n"),
            From ! {self(), line_is_busy},
            test_call();
        {_From, line_is_busy} -> 
            io:format("Message sended line is busy ~n"),
            test_call(); 
        {From, stop} ->
            io:format("Message sended stop ~n"),
            disable(From);
        M -> io:format("Shit happened connecting ~p~n", [M])
    end.

connected() ->
    receive
        {From, connect_request} ->
            From ! {self(), line_is_busy},
            connected();
        {From, call_end} -> 
            From ! {self(), call_ended},
            idle();
        {From, {message, Message}} ->
            io:format("Message recieved from ~p~n", [From]),
            From ! {self(), {message, Message}},
            connected();
        {From, stop} ->
            disable(From)
    end.

disable(From) -> From ! {self(), disabled}.

test_call() ->
    io:format("TestCallStarted ~p~n", [self()]),
    DispatchPid = whereis(dispatcher),
    PhonesList = [
                  PhonePid || PhonePid <- phone_dispatcher:phone_list(DispatchPid), PhonePid =/= self()
                 ],
    Client = lists:nth(rand:uniform(length(PhonesList)), PhonesList),
    io:format("Client~p~n", [Client]),
    connecting(Client).
