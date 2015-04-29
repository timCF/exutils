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
      Stream.map(args, &(make_arg(&1))) |> Enum.join("&")
    end
  end  


  defmodule SQL do
    def get_question_marks(num) when (is_integer(num) and (num > 0)) do
      "(#{Stream.map(1..num, fn(_) -> "?" end ) |> Enum.join(",")})"
    end
    def fields(lst) do
      "(#{Enum.join(lst, ",")})"
    end
    def duplication_part(lst) do
      Stream.map(lst, fn(field) -> "#{field} = values(#{field})" end ) |> Enum.join(",")
    end

    def make_duplication_insert(%{table_name: table_name, fields: fields, unique_fields: unique_fields, rec_num: rec_num}) when ( is_binary(table_name) and is_list(fields) and is_list(unique_fields) and is_integer(rec_num) and (rec_num > 0) ) do
      "INSERT INTO #{table_name} #{fields(fields)} VALUES #{make_results_question_marks(fields, rec_num)} ON DUPLICATE KEY UPDATE #{duplication_part(fields--unique_fields)};"
    end
    
    def make_results_question_marks(fields, rec_num) do
      marks = length(fields) |> get_question_marks
      " #{Stream.map(1..rec_num, fn(_) -> marks end ) |> Enum.join(",")} "
    end

    #
    # checks
    #

    defmacro prepare_packets(some) do
      quote location: :keep do
        case unquote(some) do
          some when is_tuple(some) ->
            case :erlang.size(some) > 0 do
              true -> [some]
              false -> :error
            end
          some_else when is_list(some_else) ->
            case Enum.all?(some_else, &is_tuple/1) do
              false -> :error
              true -> 
                case Enum.all?(some_else, &(:erlang.size(&1) > 0)) do
                  false -> :error
                  true -> some_else
                end
            end
          something -> :error
        end
      end
    end

    defmacro check_packets_ok(packets) do
      quote location: :keep do
        case Exutils.SQL.prepare_packets(unquote(packets)) do
          :error -> {:error, unquote(packets)}
          some -> 
            case Enum.all?(some, fn(el) -> elem(el, 0) == :ok_packet end) do
              true -> :ok
              false -> {:error, unquote(packets)}
            end
        end
      end
    end

    defmacro check_packets_deadlock(packets) do
      quote location: :keep do
        case Exutils.SQL.prepare_packets(unquote(packets)) do
          :error -> {:error, unquote(packets)}
          some_else -> 
            resbool = Enum.all?(some_else, 
                        fn(el) -> 
                          (elem(el, 0) == :ok_packet) or 
                          (Tuple.to_list(el) |> Enum.member?('Deadlock found when trying to get lock; try restarting transaction')) or
                          (Tuple.to_list(el) |> Enum.member?('Lock wait timeout exceeded; try restarting transaction'))
                        end) and 
                      Enum.any?(some_else, 
                        fn(el) -> 
                          (Tuple.to_list(el) |> Enum.member?('Deadlock found when trying to get lock; try restarting transaction')) or
                          (Tuple.to_list(el) |> Enum.member?('Lock wait timeout exceeded; try restarting transaction'))
                        end)
            case resbool do
              true -> :ok
              false -> {:error, unquote(packets)}
            end
        end
      end
    end

  end



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
  
  
  
  defmacro safe body do
    quote location: :keep do
      case ExTask.run( fn() -> unquote(body) end )
          |> ExTask.await(:infinity) do
        {:result, res} -> res
        error -> error
      end
    end
  end
  
  def pmap_lim([], _, _, _), do: []
  def pmap_lim(lst, num, threads_limit, func) when ((threads_limit > 0) and (num > 0)) do 
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



  def split_list(lst, len) when (is_list(lst) and is_integer(len) and (len > 0)), do: split_list_inner(lst, len, []) |> :lists.reverse

  def split_list_inner([], len, res) when (is_integer(len) and (len > 0)), do: res
  def split_list_inner(lst, len, res) when (is_list(lst) and is_integer(len) and (len > 0)) do
  	{el, rest} = Enum.split(lst, len)
  	split_list_inner(rest, len, [el|res])	
  end
  
  
  def sha1_str(inp) when is_binary(inp) do
    :crypto.hash(:sha, inp)
    |> :erlang.binary_to_list
    |> Enum.map(&([hex(div &1, 16), hex(rem &1, 16)]))
    |> List.flatten
    |> :erlang.list_to_binary
  end
  
  def md5_str(inp) when is_binary(inp) do
    :erlang.md5(inp)
    |> :erlang.binary_to_list
    |> Enum.map(&([hex(div &1, 16), hex(rem &1, 16)]))
    |> List.flatten
    |> :erlang.list_to_binary
  end
  defp hex(n) when (n < 10), do: ('0' |> List.first) + n
  defp hex(n) when ((n>=10) and (n < 16)), do: ('a' |> List.first) + n - 10


  defmodule BinArith do

    @is_number_regexp ~r/^([-]?(([1-9](\d+)?)|0|((([1-9](\d+)?)|0)\.(\d+))))$/
    @is_integer_regexp ~r/^([-]?(([1-9](\d+)?)|0))$/
    @is_float_regexp ~r/^([-]?((([1-9](\d+)?)|0)\.(\d+)))$/

    def parsable_number(bin) when is_binary(bin), do: Regex.match?(@is_number_regexp, bin)
    def parsable_number(_), do: false

    def parsable_integer(bin) when is_binary(bin), do: Regex.match?(@is_integer_regexp, bin)
    def parsable_integer(_), do: false

    def parsable_float(bin) when is_binary(bin), do: Regex.match?(@is_float_regexp, bin)
    def parsable_float(_), do: false

    #
    # next public funcs work correctly only when parsable_number(bin) == true !!! (float | int)
    #

    def maybe_to_int_normalize(bin) when is_binary(bin) do
      {sign, bin} = make_unsigned(bin)
      case parsable_integer(bin) do
        true -> "#{sign}#{bin}"
        false ->
          case String.strip(bin, ?0) |> String.split(".") do
            ["", ""] -> "0"
            ["", fl] -> "#{sign}0.#{fl}"
            [int, ""] -> "#{sign}#{int}"
            [int, fl] -> "#{sign}#{int}.#{fl}"
          end
      end
    end
    def maybe_to_int_normalize(some), do: some

    def split_number(bin) when is_binary(bin) do
      {sign, bin} = make_unsigned(bin)
      case String.split(bin, ".") do
        [one] -> ["#{sign}#{one}", "0"]
        [one, two] -> ["#{sign}#{one}", "#{sign}0.#{two}"]
      end
    end

    def mult_10(bin, dig_up) when (is_binary(bin) and is_integer(dig_up) and (dig_up > 0)) do
      {sign, bin} = make_unsigned(bin)
      case parsable_integer(bin) do
        true -> sign<>mult_10_int_unsigned(bin, dig_up)
        false -> sign<>mult_10_float_unsigned(bin, dig_up)
      end
    end

    def div_10(bin, dig_down) when (is_binary(bin) and is_integer(dig_down) and (dig_down > 0)) do
      {sign, bin} = make_unsigned(bin)
      case parsable_integer(bin) do
        true -> sign<>div_10_int_unsigned(bin, dig_down)
        false -> sign<>div_10_float_unsigned(bin, dig_down)
      end
    end

    #
    # priv funcs
    #

    defp make_unsigned(<<"-", unsigned::binary>>), do: {"-",unsigned}
    defp make_unsigned(some), do: {"", some}

    defp mult_10_int_unsigned("0", _), do: "0"
    defp mult_10_int_unsigned(bin, dig_up), do: "#{bin}#{Stream.map(1..dig_up, fn(_) -> "0" end ) |> Enum.join}"
    defp mult_10_float_unsigned(bin, dig_up) do
      [int, fl] = String.split(bin, ".")
      fl = "#{fl}#{Stream.map(1..dig_up, fn(_) -> "0" end ) |> Enum.join}"
      {to_add, rest_fl} = String.split_at(fl, dig_up)
      case String.strip("#{int}#{to_add}.#{rest_fl}", ?0) |> String.split(".") do
        ["", ""] -> "0"
        ["", fl] -> "0.#{fl}"
        [int, ""] -> int
        [int, fl] -> "#{int}.#{fl}"
      end
    end

    defp div_10_int_unsigned("0", _), do: "0"
    defp div_10_int_unsigned(bin, dig_down) do
      {int, fl} = String.split_at("#{Stream.map(1..dig_down, fn(_) -> "0" end ) |> Enum.join}#{bin}", -1 * dig_down)
      case String.strip("#{int}.#{fl}", ?0) |> String.split(".") do
        ["", ""] -> "0"
        ["", fl] -> "0.#{fl}"
        [int, ""] -> int
        [int, fl] -> "#{int}.#{fl}"
      end
    end
    defp div_10_float_unsigned(bin, dig_down) do
      [int, old_fl] = String.split(bin, ".")
      {int, fl} = String.split_at("#{Stream.map(1..dig_down, fn(_) -> "0" end ) |> Enum.join}#{int}", -1 * dig_down)
      case String.strip("#{int}.#{fl}#{old_fl}", ?0) |> String.split(".") do
        ["", ""] -> "0"
        ["", fl] -> "0.#{fl}"
        [int, ""] -> int
        [int, fl] -> "#{int}.#{fl}"
      end
    end


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
