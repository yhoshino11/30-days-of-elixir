# $ erlc support/sha1.erl && mv sha1.beam support/
# $ elixir 23-digest.exs

:code.load_abs('support/sha1')

ExUnit.start

defmodule MiscTest do
  use ExUnit.Case

  test 'sha1' do
    assert :sha1.hexstring('foo') == '0BEEC7B5EA3F0FDBC95D0DD47F3C5BC275DA8A33'
  end

  test 'md5' do
    assert :crypto.hash(:md5, 'foo') |> :sha1.bin2hex == 'ACBD18DB4CC2F85CEDEF654FCCC4A4D8'
  end
end
