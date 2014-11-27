defmodule ExutilsTest do
  use ExUnit.Case
  require Exutils

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

end
