defmodule EvercamMedia.UserControllerTest do
  use EvercamMedia.ConnCase

  test "POST /v1/users" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    params = %{ "user" => %{ firstname: "John" , lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password" } }
    conn = conn()
      |> post("/v1/registrations", params)

    response = json_response(conn, 201)

    assert response["data"]["user"]["firstname"] == "John"
    assert response["data"]["user"]["lastname"] == "Doe"
    assert response["data"]["user"]["country_id"] == country.id
    refute response["data"]["user"]["id"] == ""
    assert response["data"]["token"] == AccessToken.active_token_for(response["data"]["user"]["id"]).request
  end
end
