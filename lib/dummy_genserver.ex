defmodule DummyGenServer do
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    IO.puts "Starting #{__MODULE__}"
    {:ok, []}
  end

  def handle_call({:call, timeout}, _from, _state) do
    IO.puts "#{__MODULE__} | Received message {:call, #{timeout}} from Bomber. | #{:os.system_time(:millisecond)}"
    :timer.sleep(timeout)
    IO.puts "#{__MODULE__} | Terminating with normal signal | #{:os.system_time(:millisecond)}"
    {:stop, :normal, :dummy}
  end
end

defmodule Serializer do
  use GenServer

  def start_link(flag) do
    case GenServer.start_link(__MODULE__, [flag], name: __MODULE__) do
      {:error, {:already_started, pid}} ->
        IO.puts "#{__MODULE__} | Already started, killing the process and restarting | #{:os.system_time(:millisecond)}"
        Process.exit(pid, :normal)
        GenServer.start_link(__MODULE__, [flag], name: __MODULE__)
      res -> res
    end
  end

  def init([:foo]) do
    IO.puts("Starting #{__MODULE__}")
    Process.flag(:trap_exit, false)
    {:ok, []}
  end

  def init([:trap_exit]) do
    IO.puts("Starting #{__MODULE__} with trap_exit = true | #{:os.system_time(:millisecond)}")
    Process.flag(:trap_exit, true)
    {:ok, []}
  end

  def handle_call({mod, payload}, _from, _state) do
    IO.puts "#{__MODULE__} | Received message {#{mod}, #{inspect payload}} | #{:os.system_time(:millisecond)}"
    GenServer.call(mod, payload)
    {:reply, :ok, :dummy}
  end

  def handle_call({mod, payload, :try_catch}, _from, _state) do
    IO.puts "#{__MODULE__} | Received message {#{mod}, #{inspect payload}} | #{:os.system_time(:millisecond)}"
    try do
      GenServer.call(mod, payload)
    catch
      :exit, e -> IO.puts "#{__MODULE__} | Got error #{inspect e} | #{:os.system_time(:millisecond)}"
           DummyGenServer.start_link()
    end
    {:reply, :ok, :dummy}
  end

  def handle_info({:EXIT, _from, :normal}, _state) do
    IO.puts "#{__MODULE__} | Oh no, I got normal exit signal! :( | #{:os.system_time(:millisecond)}"
    {:noreply, :dummy}
  end
end

defmodule Bomber do
  use GenServer
  def call_via_serializer_no_try_catch() do
    Serializer.start_link(:foo)
    DummyGenServer.start_link()
    spawn(fn -> GenServer.call(Serializer, {DummyGenServer, {:call, 1_000}}) end)
    GenServer.call(Serializer, {DummyGenServer, {:call, 2_000}})
  end

  def call_via_serializer_no_try_catch(:trap_exit) do
    Serializer.start_link(:trap_exit)
    DummyGenServer.start_link()
    spawn(fn -> GenServer.call(Serializer, {DummyGenServer, {:call, 1_000}}) end)
    GenServer.call(Serializer, {DummyGenServer, {:call, 2_000}})
  end

  def call_direct() do
    DummyGenServer.start_link()
    spawn(fn -> GenServer.call(DummyGenServer, {:call, 1_000}) end)
    GenServer.call(DummyGenServer, {:call, 2_000})
  end

  def call_via_serializer_w_try_catch() do
    Serializer.start_link(:foo)
    DummyGenServer.start_link()
    spawn(fn -> GenServer.call(Serializer, {DummyGenServer, {:call, 1_000}, :try_catch}) end)
    GenServer.call(Serializer, {DummyGenServer, {:call, 2_000}, :try_catch})
  end
end
