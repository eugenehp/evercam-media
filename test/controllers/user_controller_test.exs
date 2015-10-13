defmodule EvercamMedia.UserControllerTest do
  use EvercamMedia.ConnCase

  test "POST /v1/users - creates the user and returns the json" do
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

  test "POST /v1/users - returns a conflict error for a duplicate user name" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    {:ok, _user } = EvercamMedia.Repo.insert(%User{ firstname: "John", lastname: "Doe", 
        email: "johndoe@example.com", username: "johnd", country_id: country.id, password: "some_password"})

    params = %{ "user" => %{ firstname: "John" , lastname: "Dade", 
        email: "john@dade.com", username: "johnd", country_id: country.id, password: "some_password" } }

    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 409)
    assert response["errors"]["username"], ["has already been taken"]
  end

  test "POST /v1/users - returns a conflict error for a duplicate email address" do
    {:ok, country } = EvercamMedia.Repo.insert(%Country{ name: "Whatever", iso3166_a2: "WHTEVR" })
    {:ok, _user } = EvercamMedia.Repo.insert(%User{ firstname: "John", lastname: "Doe", 
        email: "johnd@example.com", username: "johnd", country_id: country.id, password: "some_password"})

    params = %{ "user" => %{ firstname: "John" , lastname: "Dade", 
        email: "johnd@example.com", username: "johndade", country_id: country.id, password: "some_password" } }

    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 409)
    assert response["errors"]["email"], ["has already been taken"]
  end

  test "POST /v1/users - returns a HTTP 400 for blank params" do
    params = %{ "user" => %{ firstname: "" , lastname: "", email: "", username: "", country_id: "", password: "" } }

    conn = conn()
      |> post("/v1/users", params)

    response = json_response(conn, 400)
  end
end
