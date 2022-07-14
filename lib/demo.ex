defmodule Demo.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Plug.Cowboy, plug: Demo.Router, scheme: :http, options: [port: 8000]},
      Demo.Window
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

defmodule Demo.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, "<h1>Demo</h1><img src='/logo.png'>")
  end

  get "/logo.png" do
    conn
    |> put_resp_content_type("image/png")
    |> Plug.Conn.send_file(200, "#{Application.app_dir(:wx)}/priv/erlang-logo128.png")
  end

  match _ do
    send_resp(conn, 404, "oops")
  end
end

defmodule Demo.Window do
  use GenServer, restart: :transient

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init(_) do
    wx = :wx.new()
    f = :wxFrame.new(wx, -1, "Demo", pos: {100, 100}, size: {500, 500})
    :wxFrame.show(f)
    :wxFrame.connect(f, :close_window, skip: true)
    :wxWebView.new(f, -1, size: {500, 500}, url: "http://localhost:8000")
    {:ok, nil}
  end

  @impl true
  def handle_info({:wx, _, _, _, {:wxClose, :close_window}}, state) do
    :init.stop()
    {:stop, :shutdown, state}
  end
end
