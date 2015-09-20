ExUnit.start

defmodule MapTest do
  use ExUnit.Case, async: true

  def sample do
    %{foo: 'bar', baz: 'quz'}
  end

  test 'Map.get' do
    assert Map.get(sample, :foo)          == 'bar'
    assert Map.get(sample, :non_existent) == nil
  end

  test '[]' do
    assert sample[:foo]          == 'bar'
    assert sample[:non_existent] == nil
  end

  test '.' do
    assert sample.foo == 'bar'
    assert_raise KeyError, fn ->
      sample.non_existent
    end
  end

  test 'Map.fetch' do
    {:ok, val} = Map.fetch(sample, :foo)
    assert val == 'bar'
    :error = Map.fetch(sample, :non_existent)
  end

  test 'Map.put' do
    assert Map.put(sample, :foo, 'bob') == %{foo: 'bob', baz: 'quz'}
    assert Map.put(sample, :far, 'bar') == %{foo: 'bar', baz: 'quz', far: 'bar'}
  end

  test 'Update map using pattern matching syntax' do
    assert %{sample | foo: 'bob'} == %{foo: 'bob', baz: 'quz'}
    assert_raise KeyError, fn ->
      %{sample | far: 'bob'}
    end
  end

  test 'Map.values' do
    assert Enum.sort(Map.values(sample)) == ['bar', 'quz']
  end
end
