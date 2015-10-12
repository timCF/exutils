defmodule Exutils do

  @greg_epoche :calendar.datetime_to_gregorian_seconds({{1970,1,1},{0,0,0}})

  @type date :: {non_neg_integer, non_neg_integer, non_neg_integer}
  @type datetime :: {{non_neg_integer(),1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12,1..255},{byte(),byte(),byte()}}

  ####################
  ### useful funcs ###
  ####################

  #
  # pack - processing of items
  #

  @spec process_items_pack(Enum.t, non_neg_integer, (Enum.t -> any), Enum.t) :: Enum.t
  def process_items_pack(lst,num,lambda,result \\ [])
  def process_items_pack([],_,_,result), do: Enum.reverse(result)
  def process_items_pack(lst,num,lambda,result) when (is_list(lst) and is_integer(num) and (num > 0) and is_function(lambda,1)) do
    {todo,rest} = Enum.split(lst,num)
    process_items_pack(rest,num,lambda,[lambda.(todo)|result])
  end

  @spec each_pack(Enum.t, non_neg_integer, (Enum.t -> any)) :: :ok
  def each_pack([], _, _), do: :ok
  def each_pack(lst, num, lambda) do
    {todo,rest} = Enum.split(lst,num)
    lambda.(todo)
    each_pack(rest, num, lambda)
  end

  #
  # some system funcs
  #

  @spec get_os :: String.t | nil
  def get_os do
    case Enum.filter([~r/DARWIN/, ~r/LINUX/, ~r/CYGWIN/], &(Regex.match?(&1, :os.cmd('uname -s') |> :erlang.list_to_binary |> String.strip |> String.upcase))) do
      [~r/DARWIN/] -> "mac"
      [~r/LINUX/] -> "linux"
      [~r/CYGWIN/] -> "cygwin"
      _ -> nil
    end
  end

  @spec make_uuid :: String.t
  def make_uuid, do: :uuid.get_v4(:strong) |> :uuid.uuid_to_string |> to_string

  @spec priv_dir(atom) :: String.t
  def priv_dir(name), do: :code.priv_dir(name) |> :erlang.list_to_binary

  #
  # funcs to operate with time
  #

  @spec zero_pad(String.t | integer) :: String.t
  @spec zero_pad(String.t | integer, non_neg_integer) :: String.t
  def zero_pad(string), do: zero_pad(string, 2)
  def zero_pad(string, len) when is_integer(string), do: zero_pad(:erlang.integer_to_binary(string), len)
  def zero_pad(string, len) when is_binary(string) do
    case String.length(string) do
      slen when slen >= len -> string
      slen -> << String.duplicate("0", (len - slen))::binary, string::binary >>
    end
  end

  @spec makestamp :: non_neg_integer
  def makestamp do
    {a, b, c} = :os.timestamp
    a*1000000000 + b*1000 + div(c,1000)
  end

  @spec unixtime_to_datetime(non_neg_integer) :: datetime
  def unixtime_to_datetime(int) when (is_integer(int) and (int >= 0)), do: :calendar.gregorian_seconds_to_datetime(@greg_epoche + int)
  @spec timestamp_to_datetime(non_neg_integer | String.t) :: datetime
  def timestamp_to_datetime(<<a :: binary-size(4), b :: binary-size(6),  c :: binary-size(6)>>) do
    {String.to_integer(a), String.to_integer(b), String.to_integer(c)}
    |> :calendar.now_to_universal_time
  end
  def timestamp_to_datetime( input = <<_ :: binary-size(4), _ :: binary-size(6),  _ :: binary-size(3)>>), do: timestamp_to_datetime(input<>"000")
  def timestamp_to_datetime(some) when is_integer(some), do: (Integer.to_string(some) |> timestamp_to_datetime)

  @spec prepare_verbose_datetime(datetime) :: String.t
  def prepare_verbose_datetime({{y, m, d},{h, min, s}}), do: "#{y}-#{zero_pad(m)}-#{zero_pad(d)} #{zero_pad(h)}:#{zero_pad(min)}:#{zero_pad(s)}"
  @spec make_verbose_datetime :: String.t
  def make_verbose_datetime, do: (:os.timestamp |> :calendar.now_to_universal_time |> prepare_verbose_datetime)
  @spec make_verbose_datetime(integer) :: String.t
  def make_verbose_datetime(delta) do
    (now_to_int(:os.timestamp) + delta)
    |> int_to_now
    |> :calendar.now_to_universal_time
    |> prepare_verbose_datetime
  end

  @spec now_to_int(date) :: non_neg_integer
  def now_to_int({f,s,t}), do: (f*1000000*1000000 + s*1000000 + t)

  @spec int_to_now(integer) :: date
  def int_to_now(num) do
    {
      div(num,1000000*1000000),
      div(num,1000000) |> rem(1000000),
      rem(num,1000000)
    }
  end

  ####################
  ### legacy shits ###
  ####################

  # pretty printing
  @spec give_tab(non_neg_integer, String.t) :: String.t
  defp give_tab(num, res \\ "")
  defp give_tab(0, res), do: res
  defp give_tab(tab, res), do: give_tab(tab-1, res<>"\t")
  
  @spec detail_show(any, non_neg_integer) :: String.t
  def detail_show(some, tab \\ 0)
  def detail_show(map, tab) when is_map(map) do
    maybe_struct_to_map(map)
    |> Dict.to_list
    |> Enum.reduce("", fn({k, v}, res) ->
        res<>"\n"<>give_tab(tab)<>"#{inspect k}: "<>detail_show(v, tab+1)
    end)
  end
  def detail_show(lst, tab) when is_list(lst) do
    Enum.reduce(lst, "", fn(el, res) ->
      res<>"\n"<>give_tab(tab)<>detail_show(el, tab+1)
    end)
  end
  def detail_show(some, _) when is_binary(some), do: some
  def detail_show(some, _), do: inspect(some)
  #transform any struct to map
  @spec maybe_struct_to_map(any) :: any 
  defp maybe_struct_to_map(str = %{}) do
    Map.delete(str, :__struct__)
    |> Dict.to_list
    |> Enum.reduce(%{}, fn({k, v}, res) ->
          Dict.put(res, k, maybe_struct_to_map(v))
    end)
  end
  defp maybe_struct_to_map(some_else), do: some_else

  @spec makeid :: non_neg_integer
  def makeid do
    {a, b, c} = :erlang.timestamp
    a*1000000000000 + b*1000000 + c
  end
  @spec get_date :: String.t
  def get_date, do: :os.cmd('date') |> :erlang.list_to_binary |> String.strip

  @spec makecharid(non_neg_integer) :: String.t
  def makecharid(n \\ 30) do
    makeid |> rem(100) |> :crypto.rand_bytes |> :crypto.rand_seed
    :crypto.strong_rand_bytes(n) |> :base64.encode
  end
  

  #
  # some special funcs
  #
  
  
  defmodule HTTP do
    def make_arg({key, value}) do
      "#{key}=#{value |> to_string |> URI.encode_www_form}"
    end
    def make_args(args) do
      Stream.map(args, &(make_arg(&1))) |> Enum.join("&")
    end
  end  

  @spec prepare_to_jsonify(map | list, map) :: map | list 
  def prepare_to_jsonify(subj, opts \\ %{})
  def prepare_to_jsonify(hash, opts) when (is_map(hash) or is_list(hash)) do
    hash = HashUtils.struct_degradation(hash)
    case HashUtils.is_hash?(hash) and (hash != []) do
      true -> 
        if  HashUtils.keys(hash)
              |> Enum.any?(&( not(is_atom(&1) or is_binary(&1) or is_number(&1)) )) do
          raise "Exutils : can't jsonify hash. Keys must be atom, binary or number. #{inspect hash}"
        end
        HashUtils.modify_all(hash, &(prepare_to_jsonify(&1, opts)))
          |> HashUtils.to_map
      false ->
        Enum.map(hash, &(prepare_to_jsonify(&1, opts)))
    end
  end
  def prepare_to_jsonify(some, _opts) when is_atom(some), do: Atom.to_string(some)
  def prepare_to_jsonify(some, opts = %{tuple_values_to_lists: true}) when is_tuple(some), do: (Tuple.to_list(some) |> Enum.map(&(prepare_to_jsonify(&1, opts))))
  def prepare_to_jsonify(some, opts) when is_tuple(some), do: (raise "Exutils : can't jsonify tuples-in-values with these settings. #{inspect opts}")
  def prepare_to_jsonify(some, _opts), do: some
  
  
  
  defmacro safe(body, ttl \\ :infinity) do
    quote location: :keep do
      case ExTask.run( fn() -> unquote(body) end )
          |> ExTask.await(unquote(ttl)) do
        {:result, res} -> res
        error -> {:error, error}
      end
    end
  end

  defmacro tc(body, callback) do
    quote location: :keep do
      {time, res} = :timer.tc(fn() -> unquote(body) end)
      unquote(callback).(time)
      res
    end
  end

  def retry(lambda, predicate, limit \\ 100, ttl \\ 100, attempt \\ 0)
  def retry(lambda, predicate, :infinity, ttl, attempt) do
    res = lambda.()
    case predicate.(res) do
      true -> res
      false -> 
        :timer.sleep(ttl)
        retry(lambda, predicate, :infinity, ttl, attempt)
    end
  end
  def retry(lambda, _, limit, _, attempt) when (attempt > limit), do: lambda.()
  def retry(lambda, predicate, limit, ttl, attempt) when is_integer(limit) do
    res = lambda.()
    case predicate.(res) do
      true -> res
      false -> 
        :timer.sleep(ttl)
        retry(lambda, predicate, limit, ttl, attempt + 1)
    end
  end
  
  def pmap_lim([], _, _, _), do: []
  def pmap_lim(lst, num, threads_limit, func) when ((threads_limit > 0) and (num > 0)) do 
    lst = Enum.to_list(lst)
    case (length(lst) / num) > threads_limit do
      true -> 
        case round(length(lst) / threads_limit) do
          0 -> pmap(lst, 1, func)
          int -> pmap(lst, int, func)
        end
      false -> 
        pmap(lst, num, func)
    end
  end

  def pmap([], _, _), do: []
  def pmap(lst, num, func) when (num > 0) do
      :rpc.pmap({__MODULE__, :pmap_proxy}, [func], split_list_pmap(lst, num, []))
      |> :lists.reverse
      |> :lists.concat
  end
  defp split_list_pmap(lst, num, acc) do
    case Enum.split(lst, num) do
      {el, []} -> [el|acc]
      {el, rest} -> split_list_pmap(rest, num, [el|acc])
    end
  end
  def pmap_proxy(lst, func), do: Enum.map(lst, func)


  def map_reduce(lst, acc, lenw, tlim, mapper, reducer), do: preduce_inner(lst, acc, lenw, tlim, mapper, reducer, 0)
  
  defp preduce_inner([], acc, _, _, _, _, 0), do: acc
  defp preduce_inner([], acc, lenw, tlim, mapper, reducer, workers_active) when (workers_active > 0) do
    %{counter: counter, acc: acc} = receive_preduce(acc,0,reducer)
    preduce_inner([], acc, lenw, tlim, mapper, reducer, workers_active-counter)
  end
  defp preduce_inner(lst, acc, lenw, tlim, mapper, reducer, workers_active) when (workers_active >= 0) do
    %{counter: counter, acc: acc} = receive_preduce(acc,0,reducer)
    workers_active = workers_active - counter
    preduce_init_workers(lst, lenw, mapper, tlim, workers_active)
    |> preduce_inner(acc, lenw, tlim, mapper, reducer, tlim)
  end


  defp preduce_init_workers(lst, _, _, workers_active, workers_active), do: lst
  defp preduce_init_workers(lst, lenw, mapper, tlim, workers_active) when (workers_active >= 0) and (tlim > workers_active) do
    daddy = self
    to_init = tlim - workers_active
    Enum.reduce(1..to_init, lst, 
      fn(_, lst) ->
        {to_worker, rest} = Enum.split(lst, lenw)
        spawn_link(fn() -> send(daddy, {:__00preduce00_result__, Enum.map(to_worker, mapper)} ) end)
        rest
      end)
  end
  defp receive_preduce(acc, counter, reducer) do
    receive do
      {:__00preduce00_result__, lst} -> Enum.reduce(lst, acc, reducer) |> receive_preduce(counter+1, reducer)
    after
      0 -> %{acc: acc, counter: counter}
    end
  end



  def split_list(lst, len) when (is_list(lst) and is_integer(len) and (len > 0)), do: split_list_inner(lst, len, []) |> :lists.reverse

  def split_list_inner([], len, res) when (is_integer(len) and (len > 0)), do: res
  def split_list_inner(lst, len, res) when (is_list(lst) and is_integer(len) and (len > 0)) do
  	{el, rest} = Enum.split(lst, len)
  	split_list_inner(rest, len, [el|res])	
  end
  
  @spec sha1_str(String.t) :: String.t
  def sha1_str(inp) when is_binary(inp), do: (:crypto.hash(:sha, inp) |> Base.encode16([case: :lower]))
  @spec md5_str(String.t) :: String.t
  def md5_str(inp) when is_binary(inp), do: (:erlang.md5(inp) |> Base.encode16([case: :lower]))

  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      # Define workers and child supervisors to be supervised
      # worker(Exutils.Worker, [arg1, arg2, arg3])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exutils.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
