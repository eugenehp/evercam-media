defmodule EvercamMedia.RegistrationView do
  use EvercamMedia.Web, :view

  def render("create.json", %{user: user, token: token}) do
    %{data: %{ user: render_one(user, EvercamMedia.UserView, "user.json"), token: token.request } }
  end

end
