defmodule ExutilsTest do
  use ExUnit.Case
  require Exutils

  defp dec(el), do: el - 1

  test "the truth" do
    now = :os.timestamp
    assert now == Exutils.now_to_int(now) |> Exutils.int_to_now
  end

  test "safe" do
  	res = Exutils.safe(1+1)
  	assert res == 2
  end

  test "safe 2" do
  	res = Exutils.safe(1 / 0)
  	IO.inspect res
  	assert res != 2
  end

  test "pmap" do
    assert [2, 3, 4] == Exutils.pmap([1,2,3], &(&1+1))
    assert [2, 4, 6] == Exutils.pmap([1,2,3], fn(el) -> el * 2 end)
    assert [0, 1, 2] == Exutils.pmap([1,2,3], &dec/1)
  end

end
