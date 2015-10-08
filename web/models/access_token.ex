defmodule AccessToken do
  use EvercamMedia.Web, :model

  schema "access_tokens" do
    belongs_to :user, User, foreign_key: :user_id
    belongs_to :client, Client, foreign_key: :client_id
    belongs_to :grantor, User, foreign_key: :grantor_id

    field :is_revoked, :boolean, null: false
    field :expires_at, Ecto.DateTime
    field :request, :string, null: false
    field :refresh, :string
    field :updated_at, Ecto.DateTime, default: Ecto.DateTime.utc
    field :created_at, Ecto.DateTime, default: Ecto.DateTime.utc
  end

  @required_fields ~w(grantor_id is_revoked expires_at request)
  @optional_fields ~w(grantee_id refresh)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:request, on: EvercamMedia.Repo)
  end

  def active_token_for(user_id) do
    EvercamMedia.Repo.one from t in AccessToken,
    where: t.user_id == ^user_id and t.is_revoked == false and t.expires_at > ^Ecto.DateTime.utc
  end

end
