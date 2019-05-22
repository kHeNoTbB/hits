defmodule HitsWeb.HitController do
  use HitsWeb, :controller
  # import Ecto.Query
  alias Hits.{Hit, Repository, User, Useragent}

  def index(conn, %{"repository" => repository } = params) do
    # IO.inspect(params, label: "params")
    if repository =~ ".svg" do
      # insert hit
      count = insert_hit(conn, params)
      # render badge
      render_badge(conn, count)

    else
      render(conn, "index.html", params)
    end
  end

  @doc """
  insert_hit/2 inserts the hit and other requred records

  ## Parameters

  - conn: Map the standard Plug.Conn info see: hexdocs.pm/plug/Plug.Conn.html
  - params: Struct supplied by router should include respository and user.

  Returns count.
  """
  def insert_hit(conn, params) do
    useragent = Hits.get_user_agent_string(conn)

    # remote_ip comes in as a Tuple {192, 168, 1, 42} >> 192.168.1.42 (dot quad)
    ip = Enum.join(Tuple.to_list(conn.remote_ip), ".")

    # insert the useragent:
    useragent_id = Useragent.insert(%Useragent{name: useragent, ip: ip})

    # insert the user:
    user_id = User.insert(%User{name: params["user"]})

    # strip ".svg" from repo name and insert:
    repository = params["repository"] |> String.replace(".svg", "")
    repository_attrs = %Repository{name: repository, user_id: user_id}
    repository_id = Repository.insert(repository_attrs)

    # insert the hit record:
    hit_attrs = %Hit{repo_id: repository_id, useragent_id: useragent_id}
    Hit.insert(hit_attrs)
  end


  @doc """
  render_badge/2 renders the badge for the url requested in conn

  ## Parameters

  - conn: Map the standard Plug.Conn info see: hexdocs.pm/plug/Plug.Conn.html
  - count: Number the view/hit count to be displayed in the badge.

  Returns Http response to end-user's browser with the svg (XML) of the badge.
  """
  def render_badge(conn, count) do
    conn
    |> put_resp_content_type("image/svg+xml")
    |> send_resp(200, Hits.make_badge(count))
  end
end
