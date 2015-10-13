####################
### legacy shits ###
####################

defmodule Exutils.SQL do

  @type stringifible :: [String.t | atom | number]

  @spec get_question_marks(pos_integer) :: String.t
  def get_question_marks(num) when (is_integer(num) and (num > 0)) do
    "(#{Stream.map(1..num, fn(_) -> "?" end ) |> Enum.join(",")})"
  end
  @spec fields([stringifible]) :: String.t
  def fields(lst) do
    "(#{Enum.join(lst, ",")})"
  end
  @spec duplication_part([stringifible]) :: String.t
  def duplication_part(lst) do
    Stream.map(lst, fn(field) -> "#{field} = values(#{field})" end ) |> Enum.join(",")
  end

  @spec make_duplication_insert(%{table_name: String.t, fields: [stringifible], unique_fields: [stringifible], rec_num: pos_integer}) :: String.t
  def make_duplication_insert(%{table_name: table_name, fields: fields, unique_fields: unique_fields, rec_num: rec_num}) when ( is_binary(table_name) and is_list(fields) and is_list(unique_fields) and is_integer(rec_num) and (rec_num > 0) ) do
    "INSERT INTO #{table_name} #{fields(fields)} VALUES #{make_results_question_marks(fields, rec_num)} ON DUPLICATE KEY UPDATE #{duplication_part(fields--unique_fields)};"
  end
  
  @spec make_results_question_marks(list, pos_integer) :: String.t
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