defmodule EvercamMedia.ChangesetView do
  use EvercamMedia.Web, :view

  def render("error.json", %{changeset: changeset}) do
    %{errors: changeset}
  end

end
