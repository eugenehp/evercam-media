defmodule EvercamMedia.UserController do
  use EvercamMedia.Web, :controller

  def create(conn, %{ "user" => user_params }) do
    user_changeset = User.changeset(%User{}, user_params)

    if user_changeset.valid? do
      case Repo.insert(user_changeset) do
        { :ok, user } ->
          {:ok, exp_date } = Calendar.DateTime.now!("UTC") |> Calendar.DateTime.advance(3600) 
          {:ok, expiry_date } = Calendar.DateTime.to_erl(exp_date) |> Ecto.DateTime.cast
          token = Ecto.Model.build(user, :access_tokens, is_revoked: false, request: UUID.uuid4(:hex), expires_at: expiry_date )

          Repo.insert(token) |> handle_token_insert(user, conn)
        { :error, changeset } ->
          conn |> handle_error(:conflict, changeset)
      end
    else
      conn |> handle_error(:bad_request, user_changeset)
    end
  end

  def update(conn, %{ "user" => user_params }) do
  end

  defp handle_token_insert({:ok, token}, user, conn) do
    conn
    |> put_status(:created)
    |> put_resp_header("access-control-allow-origin", "*")
    |> render("user.json", %{ user: user, token: token })
  end

  defp handle_token_insert({:error, changeset}, changeset, conn) do
    conn |> handle_error(:unprocessable_entity, changeset)
  end

  defp handle_error(conn, status, changeset) do
    conn
    |> put_status(status)
    |> put_resp_header("access-control-allow-origin", "*")
    |> render(EvercamMedia.ChangesetView, "error.json", changeset: changeset)
  end
end
