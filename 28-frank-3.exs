# Improvement
# support for matching on parameters - not regex match

require Record

defmodule Frank do
  Record.defrecord :mod, Record.extract(:mod, from_lib: "inets/include/httpd.hrl")

  def sing(module) do
    :inets.start()
    options = [server_name: 'frank', server_root: '/tmp', document_root: '/tmp', port: 3000, modules: [module]]
    {:ok, _pid} = :inets.start :httpd, options
    IO.puts "running on port 3000"
  end

  defmodule Path do
    defmacro get(path, [do: code]) do
      parts = build_pattern(path)
      quote do
        def handle(unquote(parts), data) do
          unquote(code)
        end
      end
    end

    defmacro __before_compile__(_env) do
      quote do
        def handle(_, data) do
          response(404, 'not defined')
        end
      end
    end

    defp build_pattern(path) do
      path = String.lstrip(path, ?/)
      for part <- String.split(path, "/") do
        cond do
          String.starts_with?(part, ":") ->
            {String.to_atom(String.lstrip(part, ?:)), [], nil}
          true ->
            part
        end
      end
    end

    def redirect(path, code \\ 302) do
      body = ['redirecting you to <a href="', path, '">', path, '</a>']
      response code, body, [location: path]
    end

    def sanitize(content) do
      content = Regex.replace(~r/&/, content, "\\&amp;")
      content = Regex.replace(~r/</, content, "\\&lt;")
      content = Regex.replace(~r/>/, content, "\\&gt;")
      content
    end

    def response(code, body, headers \\ []) do
      if is_binary(body) do
        body = :erlang.bitstring_to_list(body)
      end
      headers = [code: code, content_length: Integer.to_char_list(IO.iodata_length(body))] ++ headers
      {:proceed, [response: {:response, headers, body}]}
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Frank.Path

      def unquote(:do)(data) do
        [_ | path] = Frank.mod(data, :request_uri)
        path = :erlang.list_to_bitstring(path)
        parts = String.split(path, "/")
        handle(parts, data)
      end

      @before_compile Path
    end
  end
end

defmodule Test do
  use Frank

  get "/" do
    response 200, "<a href='/foo'>go to foo</a>"
  end

  get "/foo" do
    response 200, "foo!"
  end

  get "/hello/:name" do
    response 200, "greetings #{name}"
  end
end

Frank.sing(Test)
