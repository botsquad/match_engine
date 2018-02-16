defmodule MatchEngine.UnitTest do
  use ExUnit.Case

  alias MatchEngine.Unit

  test "new" do
    assert %Unit{op: :eq} = Unit.new(op: :eq)
  end

  test "validation" do
    assert_raise RuntimeError, fn -> Unit.new(op: :asdfsaf) end
  end

  @input %{"title" => "hello"}

  test "running" do
    u = Unit.new(op: :eq, arg: {"title", "hello"})
    assert 1 == Unit.run(u, @input)
    assert 0 == Unit.run(u, %{"title" => "aap"})

    u = Unit.new(op: :eq, arg: {"title", "hello"}, weight: 3)
    assert 3 == Unit.run(u, @input)
  end

  test "sim(ilarity)" do
    u = Unit.new(op: :sim, arg: {"title", "hello"})
    assert 1 == Unit.run(u, %{"title" => "hello"})
    assert 0 == Unit.run(u, %{"title" => "asdfq"})
    assert_in_delta 0.86, Unit.run(u, %{"title" => "hella"}), 0.01
  end

  test "regex" do
    # assert_raise RuntimeError, fn -> Unit.new(op: :re, arg: %{invalid: "arg"}) end

    u = Unit.new(op: :re, arg: {"title", "aap"})
    assert 1 == Unit.run(u, %{"title" => "aap"})
    assert 1 == Unit.run(u, %{"title" => "Aap"})

    # score weighted on match
    assert 0.5 == Unit.run(u, %{"title" => "Aapjes"})
    assert 0 < Unit.run(u, %{"title" => "Aapjes zijn leuke beestjes"})

    assert 0 == Unit.run(u, %{"title" => "blabla"})

    u = Unit.new(op: :re, arg: {"title", "aap"}, binary_score: true)
    assert 1 == Unit.run(u, %{"title" => "aapjes"})
    assert 0 == Unit.run(u, %{"title" => "alkdsjlkfds"})
  end

  test "not" do
    u = Unit.new(op: :not)
    |> Unit.arg(Unit.new(op: :eq, arg: {"title", "aap"}))

    assert 0 == Unit.run(u, %{"title" => "aap"})
    assert 1 == Unit.run(u, %{"title" => "not_aap"})
  end

  test "or" do
    u = Unit.new(op: :or)
    |> Unit.arg([Unit.new(op: :eq, arg: {"title", "aap"}), Unit.new(op: :eq, arg: {"title", "noot"})])

    assert 1 == Unit.run(u, %{"title" => "aap"})
    assert 1 == Unit.run(u, %{"title" => "noot"})
    assert 0 == Unit.run(u, %{"title" => "mies"})

    u = Unit.new(op: :or)
    |> Unit.arg([Unit.new(op: :eq, arg: {"title", "aap"}), Unit.new(op: :eq, arg: {"name", "bar"})])

    assert 2 == Unit.run(u, %{"title" => "aap", "name" => "bar"})
  end

  test "and" do
    u = Unit.new(op: :and)
    |> Unit.arg([Unit.new(op: :eq, arg: {"title", "aap"}), Unit.new(op: :eq, arg: {"name", "bar"})])

    assert 1 == Unit.run(u, %{"title" => "aap", "name" => "bar"})
    assert 0 == Unit.run(u, %{"title" => "aap", "name" => "xxbar"})

    u = Unit.new(op: :and)
    |> Unit.arg([Unit.new(op: :eq, arg: {"title", "aap"}, weight: 3), Unit.new(op: :eq, arg: {"name", "bar"}, weight: 2)])

    assert 6 == Unit.run(u, %{"title" => "aap", "name" => "bar"})

  end

end
