####################
### useful funcs ###
####################

defmodule Exutils.Reg do

  @escape_reg ~r/(\\*')/
  @escape_sym "\\"

  @spec escape(String.t, Regex.t, String.t) :: String.t
  def escape(bin, escape_reg \\ @escape_reg, escape_sym \\ @escape_sym) do
    case Regex.match?(escape_reg, bin) do
      false -> bin
      true -> Regex.replace(escape_reg, bin, 
          fn(_, x) ->
            lst = String.codepoints(x)
            case rem(length(lst), 2) do
              0 -> Enum.join(lst)
              1 -> Enum.join([escape_sym|lst])
            end
          end)
    end
  end

end