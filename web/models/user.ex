defmodule User do
  use EvercamMedia.Web, :model 

  schema "users" do
    belongs_to :country, Country, foreign_key: :country_id
    has_many :cameras, Camera, foreign_key: :owner_id
    has_many :camera_shares, CameraShare
    has_many :access_tokens, AccessToken

    field :username, :string
    field :password, :string
    field :firstname, :string
    field :lastname, :string
    field :email, :string

    field :updated_at, Ecto.DateTime, default: Ecto.DateTime.utc
    field :created_at, Ecto.DateTime, default: Ecto.DateTime.utc
  end

  @required_fields ~w(username password firstname lastname email country_id)
  @optional_fields ~w()

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email, [name: "ux_users_email"])
    |> unique_constraint(:username, [name: "ux_users_username"])
    |> validate_format(:email, ~r/^.+@.+\..+$/)
  end

end
