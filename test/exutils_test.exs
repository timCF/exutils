defmodule ExutilsTest do
  use ExUnit.Case
  require Exutils
  require Exutils.SQL

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

  test "split_list" do
	assert [[0,true,"1"],[2,3,4],[5]] = Exutils.split_list([0,true,"1",2,3,4,5], 3)
  end

  test "pmap" do
    assert [2, 3, 4] == Exutils.pmap([1,2,3], 2, &(&1+1))
    assert [2, 4, 6] == Exutils.pmap([1,2,3], 2, fn(el) -> el * 2 end)
    assert [0, 1, 2] == Exutils.pmap([1,2,3], 10, &dec/1)
	  lst = Enum.map(1..50, &(&1))
    assert lst == Exutils.pmap(lst, 5, &(&1))
  end

  test "pmap_lim" do
    assert [2, 3, 4] == Exutils.pmap_lim([1,2,3], 2, 2, &(&1+1))
    assert [2, 4, 6] == Exutils.pmap_lim([1,2,3], 2, 2, fn(el) -> el * 2 end)
    assert [0, 1, 2] == Exutils.pmap_lim([1,2,3], 2, 10, &dec/1)
    lst = Enum.map(1..50, &(&1))
    assert lst == Exutils.pmap_lim(lst, 5, 2, &(&1))
  end

  test "SQL.checks" do
    assert {:error, 123} == Exutils.SQL.check_packets_ok(123)
    assert :ok == Exutils.SQL.check_packets_ok({:ok_packet, 0,0,0,0})
    assert :ok == Exutils.SQL.check_packets_ok([{:ok_packet, 0,0,0,0}, {:ok_packet, 0,0,0,0}])
    assert :ok == Exutils.SQL.check_packets_ok([{:ok_packet, 0,0,0,0}, {:ok_packet, 0,0,0}])
    assert {:error, [{:ok_packet, 0,0,0,0}, {:ok_packet, 0,0,0,0}]} == Exutils.SQL.check_packets_deadlock([{:ok_packet, 0,0,0,0}, {:ok_packet, 0,0,0,0}])
    assert :ok == Exutils.SQL.check_packets_deadlock([{:error_packet, 0,0,0,'Deadlock found when trying to get lock; try restarting transaction' }, {:ok_packet, 0,0,0,0}])
  end

  test "BinArith" do

    assert not Exutils.BinArith.parsable_number(["qwe", "1"])
    assert not Exutils.BinArith.parsable_float(["qwe", "1"])
    assert not Exutils.BinArith.parsable_integer(["qwe", "1"])

    assert Exutils.BinArith.parsable_number("0.1200")
    assert Exutils.BinArith.parsable_number("2.1200")
    assert Exutils.BinArith.parsable_number("-2300")
    assert not Exutils.BinArith.parsable_number("00.1200")
    assert not Exutils.BinArith.parsable_number("0.1d200")
    assert not Exutils.BinArith.parsable_number("2.")
    assert not Exutils.BinArith.parsable_number(".203")

    assert Exutils.BinArith.parsable_float("0.1200")
    assert Exutils.BinArith.parsable_float("0.000")
    assert Exutils.BinArith.parsable_float("-0.000")
    assert Exutils.BinArith.parsable_float("-2.1200")
    assert not Exutils.BinArith.parsable_float("2300")
    assert not Exutils.BinArith.parsable_float("00.1200")
    assert not Exutils.BinArith.parsable_float("0.1d200")
    assert not Exutils.BinArith.parsable_float("2.")
    assert not Exutils.BinArith.parsable_float(".203")

    assert Exutils.BinArith.parsable_integer("-1200")
    assert Exutils.BinArith.parsable_integer("0")
    assert not Exutils.BinArith.parsable_integer("02300")
    assert not Exutils.BinArith.parsable_integer("23f00")
    assert not Exutils.BinArith.parsable_integer("2300x")

    assert "0.1" == Exutils.BinArith.mult_10("0.001", 2)
    assert "-0.1" == Exutils.BinArith.mult_10("-0.001", 2)
    assert "-0.101" == Exutils.BinArith.mult_10("-0.00101", 2)
    assert "-1.01" == Exutils.BinArith.mult_10("-0.00101", 3)
    assert "-12300.1" == Exutils.BinArith.mult_10("-123.00100", 2)
    assert "-12300" == Exutils.BinArith.mult_10("-123.00000", 2)
    assert "10000" == Exutils.BinArith.mult_10("100", 2)
    assert "-10000" == Exutils.BinArith.mult_10("-100", 2)

    assert "0.00001" == Exutils.BinArith.div_10("0.001", 2)
    assert "-0.00001" == Exutils.BinArith.div_10("-0.001", 2)
    assert "-0.00001" == Exutils.BinArith.div_10("-0.00100", 2)
    assert "-1.23001" == Exutils.BinArith.div_10("-123.00100", 2)
    assert "-1.23" == Exutils.BinArith.div_10("-123.00000", 2)
    assert "1" == Exutils.BinArith.div_10("100", 2)
    assert "-1" == Exutils.BinArith.div_10("-100", 2)
    assert "-0.103" == Exutils.BinArith.div_10("-103", 3)

    assert "0" == Exutils.BinArith.maybe_to_int_normalize("0.00")
    assert "-1" == Exutils.BinArith.maybe_to_int_normalize("-1")
    assert "123400" == Exutils.BinArith.maybe_to_int_normalize("123400.00")
    assert "-123400.001" == Exutils.BinArith.maybe_to_int_normalize("-123400.00100")
    assert "0.001" == Exutils.BinArith.maybe_to_int_normalize("0.00100")
    assert ["qwe", "1"] == Exutils.BinArith.maybe_to_int_normalize(["qwe", "1"])

  end
end
