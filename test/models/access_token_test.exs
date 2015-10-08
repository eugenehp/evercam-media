defmodule EvercamMedia.AccessTokenTest do
  use EvercamMedia.ModelCase

  test "active_token_for returns only the active token for a user" do
    { :ok, country } = Repo.insert(%Country{ name: "Aruba", iso3166_a2: "whatever" })
    { :ok, user } = Repo.insert(%User{ firstname: "John", lastname: "Doe", email: "johndoe@example.com", password: "something", username: "jdoe123", country_id: country.id })

    active_token = Ecto.Model.build(user, :access_tokens, is_revoked: false, request: UUID.uuid4(:hex), expires_at: date_in_future)
    inactive_token = Ecto.Model.build(user, :access_tokens, is_revoked: true, request: UUID.uuid4(:hex), expires_at: date_in_past)

    Repo.insert(active_token)
    Repo.insert(inactive_token)

    token = AccessToken.active_token_for(user.id)

    assert token.request == active_token.request 
  end

  defp date_in_future do
    {:ok, future_date_time } = Calendar.DateTime.now!("UTC") |> Calendar.DateTime.advance(3600) 
    {:ok, ecto_date } = Calendar.DateTime.to_erl(future_date_time) |> Ecto.DateTime.cast
    ecto_date
  end
  
  def date_in_past do
    past_date_time = Calendar.DateTime.from_erl!({{2014,10,4}, {23,44,32}}, "UTC")
    {:ok, ecto_date } = Calendar.DateTime.to_erl(past_date_time) |> Ecto.DateTime.cast
    ecto_date
  end
end
