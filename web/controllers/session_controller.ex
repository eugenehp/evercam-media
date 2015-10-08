defmodule EvercamMedia.SessionController do
  use EvercamMedia.Web, :controller

  plug :action

  def create(conn, %{ "user" => %{ "email" => email, "password" => password }}) do
  end

  def delete(conn, %{ "token" => token }) do
  end
end
