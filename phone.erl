-module(phone).
-export([enable/1, rpc/2, idle/1]).

enable(DispatchPid) -> spawn(?MODULE, idle, [DispatchPid]).

rpc(Pid, Request) ->
    Pid ! {self(), Request},
    receive
        {Pid, Response} ->
            Response
    end.

idle(DispatchPid) ->
    receive
        {From, connect_request} -> 
            From ! {self(), establishing_connect}, 
            connected(DispatchPid);
        {From, stop} ->
            From ! {self(), disable},
            disable();
        {From, _} ->
            From ! {self(), free_line},
            idle(DispatchPid)
    after rand:uniform(10000) ->
        connected(DispatchPid)
    end.

% connecting() ->
%     receive
%         {_From, connected} -> connected(); 
%         {From, stop} ->
%             From ! {self(), disable},
%             disable()
%     end.

connected(DispatchPid) ->
    receive
        {From, call_start} ->
            From ! {self(), line_is_busy},
            connected(DispatchPid);
        {From, call_end} -> 
            From ! {self(), call_ended},
            idle(DispatchPid);
        {From, {message, Message}} ->
            From ! {self(), {message, Message}},
            connected(DispatchPid);
        {From, stop} ->
            From ! {self(), disable},
            disable()
    after 50000 ->
            idle(DispatchPid)
    end.

disable() -> ok.

test_call(DispatchPid, SelfPid) ->
    PhonesList = [PhonePid || PhonePid <- phone_dispatcher:phone_list(DispatchPid), PhonePid =/= SelfPid],
    lists:nth(rand:uniform(length(PhonesList)), PhonesList).
