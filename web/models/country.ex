defmodule Country do
  use EvercamMedia.Web, :model

  schema "countries" do
    has_many :users, User

    field :iso3166_a2, :string
    field :name, :string
  end

  @required_fields ~w(name iso_3166_a2)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:iso_3166_a2)
  end
end
