defmodule Exutils do


  # pretty printing
  defp give_tab(num \\ 0, res \\ "")
  defp give_tab(0, res) do
    res
  end
  defp give_tab(tab, res) do
    give_tab(tab-1, res<>"\t")
  end
  def detail_show(some, tab \\ 0)
  def detail_show(map, tab) when is_map(map) do
    struct_to_map(map)
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
  def detail_show(some, tab) when is_binary(some) do
    some
  end
  def detail_show(some, tab) do
    "#{inspect some}"
  end
  #transform any struct to map
  defp struct_to_map(str = %{}) do
    Map.delete(str, :__struct__)
      |> Dict.to_list
        |> Enum.reduce(%{}, fn({k, v}, res) ->
          Dict.put(res, k, struct_to_map(v))
        end)
  end
  defp struct_to_map(some_else) do
    some_else
  end

  # some special funcs
  def makestamp do
    {a, b, c} = :os.timestamp
    a*1000000000 + b*1000 + round( c / 1000)
  end
  def makeid do
    {a, b, c} = :erlang.now
    a*1000000000000 + b*1000000 + c
  end
  def priv_dir(name) do
      :erlang.list_to_binary(:code.priv_dir(name))
  end
  def get_date do
    System.cmd("date") |> String.strip
  end

  def timestamp_to_datetime(<<a :: binary-size(4), b :: binary-size(6),  c :: binary-size(6)>>) do
    { String.to_integer(a), String.to_integer(b), String.to_integer(c) }
      |> :calendar.now_to_universal_time
  end
  def timestamp_to_datetime( input = <<a :: binary-size(4), b :: binary-size(6),  c :: binary-size(3)>>) do
    timestamp_to_datetime(input<>"000")
  end
  def timestamp_to_datetime(some) when (is_integer(some)) do
    timestamp_to_datetime(to_string(some))
  end

  def makecharid(n \\ 30) do
    makeid |> to_string |> :crypto.rand_seed
    :crypto.strong_rand_bytes(n) |> :base64.encode
  end
  

  #
  # some special funcs
  #

  def zero_pad(string), do: zero_pad(string, 2)
  def zero_pad(string, len) when is_integer(string) do
    zero_pad(:erlang.integer_to_binary(string), len)
  end
  def zero_pad(string, len) when is_binary(string) do
    case String.length(string) do
      slen when slen >= len -> string
      slen -> << String.duplicate("0", (len - slen))::binary, string::binary >>
    end
  end

  def prepare_verbose_datetime(input = {{y, m, d},{h, min, s}}) do
    "#{y}-#{zero_pad(m)}-#{zero_pad(d)} #{zero_pad(h)}:#{zero_pad(min)}:#{zero_pad(s)}"
  end

  def make_verbose_datetime do
    :os.timestamp |> :calendar.now_to_universal_time |> prepare_verbose_datetime
  end

  def make_verbose_datetime(delta) do
    (now_to_int(:os.timestamp) + delta)
      |> int_to_now
          |> :calendar.now_to_universal_time
              |> prepare_verbose_datetime
  end

  def now_to_int {f,s,t} do
    f*1000000*1000000 + s*1000000 + t
  end

  def int_to_now num do
    {
      div(num,1000000*1000000),
      div(num,1000000) |> rem(1000000),
      rem(num,1000000)
    }
  end
  
  
  defmodule HTTP do
    def make_arg({key, value}) do
      "#{key}=#{value |> to_string |> URI.encode_www_form}"
    end
    def make_args(args) do
      Enum.map(args, &(make_arg(&1))) |> Enum.join("&")
    end
  end  

  def prepare_to_jsonify(subj, opts \\ %{})
  def prepare_to_jsonify(hash, opts) when (is_map(hash) or is_list(hash)) do
    hash = HashUtils.struct_degradation(hash)
    case HashUtils.is_hash?(hash) do
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
  def prepare_to_jsonify(some, _opts) when is_atom(some) do
    to_string(some)
  end
  def prepare_to_jsonify(some, opts = %{tuple_values_to_lists: true}) when is_tuple(some) do
    Tuple.to_list(some) |> Enum.map( &(prepare_to_jsonify(&1, opts)) )
  end
  def prepare_to_jsonify(some, opts) when is_tuple(some) do
    raise "Exutils : can't jsonify tuples-in-values with these settings. #{inspect opts}"
  end
  def prepare_to_jsonify(some, _opts) do
    some
  end
  
  
  
  
  
  

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
