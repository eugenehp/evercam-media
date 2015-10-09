defmodule EvercamMedia.UserController do
  use EvercamMedia.Web, :controller

  def create(conn, %{ "user" => user_params }) do
    user_changeset = User.changeset(%User{}, user_params)

    user = Repo.insert!(user_changeset)
    {:ok, exp_date } = Calendar.DateTime.now!("UTC") |> Calendar.DateTime.advance(3600) 
    {:ok, expiry_date } = Calendar.DateTime.to_erl(exp_date) |> Ecto.DateTime.cast
    token = Ecto.Model.build(user, :access_tokens, is_revoked: false, request: UUID.uuid4(:hex), expires_at: expiry_date )

    case Repo.insert(token) do
      {:ok, token } ->
        conn
        |> put_status(:created)
        |> put_resp_header("access-control-allow-origin", "*")
        |> render("create.json", user: user, token: token)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_header("access-control-allow-origin", "*")
        |> render(EvercamMedia.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def update(conn, %{ "token" => token, "user" => user_params }) do
  end

end
