defmodule EvercamMedia.UserControllerTest do
  use EvercamMedia.ConnCase

  test "POST /v1/users" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    params = %{ "user" => %{ firstname: "John" , lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password" } }
    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 201)

    assert response["user"]["firstname"] == "John"
    assert response["user"]["lastname"] == "Doe"
    assert response["user"]["country_id"] == country.id
    refute response["user"]["id"] == ""
    assert response["user"]["token"] == AccessToken.active_token_for(response["user"]["id"]).request
  end
end
