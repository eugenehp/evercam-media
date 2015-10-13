defmodule EvercamMedia.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  imports other functionalities to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest

      # Alias the data repository and import query/model functions
      alias EvercamMedia.Repo
      alias EvercamMedia.Message
      alias EvercamMedia.Endpoint
      import Ecto.Model
      import Ecto.Query, only: [from: 2]

      # Import URL helpers from the router
      import EvercamMedia.Router.Helpers

      # The default endpoint for testing
      @endpoint EvercamMedia.Endpoint
    end
  end

  setup do
    # Wrap this case in a transaction
    Ecto.Adapters.SQL.begin_test_transaction(EvercamMedia.Repo)

    #camera = %Camera{config: %{"auth" => %{"basic" => %{"password" => "mehcam", "username" => "admin"}}, "external_host" => "149.13.244.32", "external_http_port" => 8100, "external_rtsp_port" => 9100, "internal_host" => "", "internal_http_port" => "", "internal_rtsp_port" => "", "snapshots" => %{"jpg" => "/Streaming/Channels/1/picture"}}, exid: "mobile-mast-test", id: 5, is_online: true, is_public: false, name: "Test Mobile Mast", owner_id: 2}
    #EvercamMedia.Repo.insert(camera)

    # Roll it back once we are done
    on_exit fn ->
      Ecto.Adapters.SQL.rollback_test_transaction(EvercamMedia.Repo)
    end

    :ok
  end
end
