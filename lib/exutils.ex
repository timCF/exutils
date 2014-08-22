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
  def priv_dir do
      :erlang.list_to_binary(:code.priv_dir(:betradar))
  end
  def get_date do
    System.cmd("date") |> String.strip
  end

  def timestamp_to_datetime(<<a :: binary-size(4), b :: binary-size(6),  c :: binary-size(6)>>) do
    { String.to_integer(a), String.to_integer(b), String.to_integer(c) }
      |> :calendar.now_to_local_time # maybe not use here local time?
  end
  def timestamp_to_datetime( input = <<a :: binary-size(4), b :: binary-size(6),  c :: binary-size(3)>>) do
    timestamp_to_datetime(input<>"000")
  end
  def timestamp_to_datetime(some) when (is_integer(some)) do
    timestamp_to_datetime(to_string(some))
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
