defmodule EvercamMedia.UserView do
  use EvercamMedia.Web, :view

  def render("user.json", %{ user: user, token: token }) do
    %{
      user: %{
        id: user.id,
        country_id: user.country_id,
        email: user.email,
        firstname: user.firstname,
        lastname: user.lastname,
        username: user.username,
        token: token.request
      }
    }
  end
end
