# GenServerBomber

This project is used to test and demo a general issue with GenServer.

The case being two processes calling the same GenServer process, and if the first one got terminated normally, the second process will throw a :normal exit signal to the mother process.

What we take from the test is that the best workaround is to use try/catch to catch the exit signal.

## Results

Bomber.call_direct/0

This does two direct calls (almost) simultaneously to the GenServer process, where the first one will stop the process with :normal exit reason after 1 second. The result shows that the second call will also throw a :normal exit signal and this might cause error in the process calling the GenServer.

```elixir
Starting Elixir.DummyGenServer
Elixir.DummyGenServer | Received message {:call, 2000} from Bomber. | ...401638
Elixir.DummyGenServer | Terminating with normal signal | ...403640
** (exit) exited in: GenServer.call(DummyGenServer, {:call, 2000}, 5000)
    ** (EXIT) normal
    (elixir) lib/gen_server.ex:774: GenServer.call/3
```

Bomber.call_via_serializer_no_try_catch/0

This does two similar calls as call_direct/0, but directed the messages to a serializer (no try_catch, and trap_exit = false) before calling the GenServer process. The Serializer is also a GenServer which in principle should make sure that one call won't be delivered until the other one is finished in the DummyGenServer.

The result is however different from my assumptions, same as call_direct/0, it throws a :normal exit signal.

```elixir
Starting Elixir.Serializer
Starting Elixir.DummyGenServer
Elixir.Serializer | Received message {Elixir.DummyGenServer, {:call, 2000}} | ...736029
Elixir.DummyGenServer | Received message {:call, 2000} from Bomber. | ...736029
Elixir.DummyGenServer | Terminating with normal signal | ...738032
** (EXIT from #PID<0.107.0>) evaluator process exited with reason: exited in: GenServer.call(DummyGenServer, {:call, 2000}, 5000)
    ** (EXIT) normal

Interactive Elixir (1.5.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
17:02:18.041 [error] GenServer Serializer terminating
** (stop) exited in: GenServer.call(DummyGenServer, {:call, 2000}, 5000)
    ** (EXIT) normal
    (elixir) lib/gen_server.ex:774: GenServer.call/3
    (gen_server_buster) lib/dummy_genserver.ex:48: Serializer.handle_call/3
    (stdlib) gen_server.erl:615: :gen_server.try_handle_call/4
    (stdlib) gen_server.erl:647: :gen_server.handle_msg/5
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: {DummyGenServer, {:call, 2000}}
State: []
```

Bomber.call_via_serializer_no_try_catch(:trap_exit)

Similar to the previous call, but trap_exit is set to true this time.

Same result as above.

```elixir
Starting Elixir.Serializer with trap_exit = true | 1524928309436
Starting Elixir.DummyGenServer
Elixir.Serializer | Received message {Elixir.DummyGenServer, {:call, 2000}} | 1524928309443
Elixir.DummyGenServer | Received message {:call, 2000} from Bomber. | 1524928309443
Elixir.DummyGenServer | Terminating with normal signal | 1524928311445
** (EXIT from #PID<0.126.0>) evaluator process exited with reason: exited in: GenServer.call(DummyGenServer, {:call, 2000}, 5000)
    ** (EXIT) normal

Interactive Elixir (1.5.0) - press Ctrl+C to exit (type h() ENTER for help)
iex(1)>
17:11:51.457 [error] GenServer Serializer terminating
** (stop) exited in: GenServer.call(DummyGenServer, {:call, 2000}, 5000)
    ** (EXIT) normal
    (elixir) lib/gen_server.ex:774: GenServer.call/3
    (gen_server_buster) lib/dummy_genserver.ex:48: Serializer.handle_call/3
    (stdlib) gen_server.erl:615: :gen_server.try_handle_call/4
    (stdlib) gen_server.erl:647: :gen_server.handle_msg/5
    (stdlib) proc_lib.erl:247: :proc_lib.init_p_do_apply/3
Last message: {DummyGenServer, {:call, 2000}}
State: []
```

Bomber.call_via_serializer_w_try_catch

Similar to Bomber.call_via_serializer_no_try_catch/0, but has a try_catch to catch the exit signal

Result: no error being thrown, can be used to avoid this type of issue.

```elixir
Starting Elixir.Serializer
Starting Elixir.DummyGenServer
Elixir.Serializer | Received message {Elixir.DummyGenServer, {:call, 2000}} | 1524928413488
Elixir.DummyGenServer | Received message {:call, 2000} from Bomber. | 1524928413488
Elixir.DummyGenServer | Terminating with normal signal | 1524928415491
Elixir.Serializer | Got error {:normal, {GenServer, :call, [DummyGenServer, {:call, 2000}, 5000]}} | 1524928415492
Starting Elixir.DummyGenServer
Elixir.Serializer | Received message {Elixir.DummyGenServer, {:call, 1000}} | 1524928415492
:ok
Elixir.DummyGenServer | Received message {:call, 1000} from Bomber. | 1524928415493
Elixir.DummyGenServer | Terminating with normal signal | 1524928416494
Elixir.Serializer | Got error {:normal, {GenServer, :call, [DummyGenServer, {:call, 1000}, 5000]}} | 1524928416494
Starting Elixir.DummyGenServer
```
