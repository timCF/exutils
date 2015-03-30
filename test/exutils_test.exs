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

end
