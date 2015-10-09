defmodule Exutils.BinArith do

  @is_number_regexp ~r/^([-]?(([1-9](\d+)?)|0|((([1-9](\d+)?)|0)\.(\d+))))$/
  @is_integer_regexp ~r/^([-]?(([1-9](\d+)?)|0))$/
  @is_float_regexp ~r/^([-]?((([1-9](\d+)?)|0)\.(\d+)))$/

  @spec parsable_number(any) :: boolean
  def parsable_number(bin) when is_binary(bin), do: Regex.match?(@is_number_regexp, bin)
  def parsable_number(_), do: false

  @spec parsable_integer(any) :: boolean
  def parsable_integer(bin) when is_binary(bin), do: Regex.match?(@is_integer_regexp, bin)
  def parsable_integer(_), do: false

  @spec parsable_float(any) :: boolean
  def parsable_float(bin) when is_binary(bin), do: Regex.match?(@is_float_regexp, bin)
  def parsable_float(_), do: false

  #
  # next public funcs work correctly only when parsable_number(bin) == true !!! (float | int)
  #

  @spec maybe_to_int_normalize(String.t) :: String.t
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

  @spec split_number(String.t) :: [String.t]
  def split_number(bin) when is_binary(bin) do
    {sign, bin} = make_unsigned(bin)
    case String.split(bin, ".") do
      [one] -> ["#{sign}#{one}", "0"]
      [one, two] -> ["#{sign}#{one}", "#{sign}0.#{two}"]
    end
  end

  @spec mult_10(String.t, pos_integer) :: String.t
  def mult_10(bin, dig_up) when (is_binary(bin) and is_integer(dig_up) and (dig_up > 0)) do
    {sign, bin} = make_unsigned(bin)
    case parsable_integer(bin) do
      true -> sign<>mult_10_int_unsigned(bin, dig_up)
      false -> sign<>mult_10_float_unsigned(bin, dig_up)
    end
  end

  @spec div_10(String.t, pos_integer) :: String.t
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

  @spec make_unsigned(String.t) :: {String.t, String.t}
  defp make_unsigned(<<"-", unsigned::binary>>), do: {"-",unsigned}
  defp make_unsigned(some), do: {"", some}

  @spec mult_10_int_unsigned(String.t, pos_integer) :: String.t
  defp mult_10_int_unsigned("0", _), do: "0"
  defp mult_10_int_unsigned(bin, dig_up), do: "#{bin}#{Stream.map(1..dig_up, fn(_) -> "0" end ) |> Enum.join}"
  @spec mult_10_float_unsigned(String.t, pos_integer) :: String.t
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

  @spec div_10_int_unsigned(String.t, pos_integer) :: String.t
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
  @spec div_10_float_unsigned(String.t, pos_integer) :: String.t
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