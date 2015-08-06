defmodule Exutils.Math do
	defmacro __using__(_) do
		quote location: :keep do
			defp mult(lst = [_|_]), do: Enum.reduce(lst,1,&(&2*&1))
			defp sum(lst = [_|_]), do: Enum.reduce(lst,0,&(&2+&1))
		end
	end
end