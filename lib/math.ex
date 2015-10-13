####################
### useful funcs ###
####################

defmodule Exutils.Math do
	defmacro __using__(_) do
		quote location: :keep do
			@spec mult([number]) :: number
			defp mult(lst = [_|_]), do: Enum.reduce(lst,1,&(&2*&1))
			@spec sum([number]) :: number
			defp sum(lst = [_|_]), do: Enum.reduce(lst,0,&(&2+&1))
		end
	end
end