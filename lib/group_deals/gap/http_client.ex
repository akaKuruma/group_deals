defmodule GroupDeals.Gap.HttpClient do
  @moduledoc """
  GenServer that maintains a shared HTTP client with cookie session.
  """

  use GenServer
  require Logger
  alias GroupDeals.Gap.HttpClient.Operation

  @server_name __MODULE__
  @base_sleep_seconds 2

  @spec start_link(any()) :: :ignore | {:error, any()} | {:ok, pid()}
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: @server_name)
  end

  @impl true
  @spec init(any()) ::
          {:ok, %{client: Req.Request.t(), jar: any()}}
          | {:stop,
             {:failed_to_initialize_session,
              {:exception, binary()}
              | {:exit, any()}
              | {:http_error, non_neg_integer()}
              | {:session_failed, map()}}}
  def init(_opts) do
    client = Operation.create_client()
    jar = Operation.create_jar()

    case Operation.create_session({client, jar}) do
      {:ok, updated_jar} ->
        {:ok, %{client: client, jar: updated_jar}}

      {:error, reason} ->
        Logger.error("Failed to create session: #{inspect(reason)}")
        {:stop, {:failed_to_initialize_session, reason}}
    end
  end

  @doc """
  Fetches a Product HTML Page from the Gap Factory homepage.
  """
  @spec fetch_product_html_page(binary()) :: {:ok, binary()} | {:error, any()}
  def fetch_product_html_page(url) do
    sleep_random()
    GenServer.call(@server_name, {:fetch_product_html_page, url})
  end

  def fetch_json_api(url) do
    sleep_random()
    GenServer.call(@server_name, {:fetch_json_api, url})
  end

  @impl true
  def handle_call({:fetch_product_html_page, url}, _from, state) do
    client = state.client
    jar = state.jar

    case Operation.fetch_product_html_page({client, jar}, url) do
      {:ok, {html_body, updated_jar}} ->
        {:reply, {:ok, html_body}, %{client: client, jar: updated_jar}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:fetch_json_api, url}, _from, state) do
    client = state.client
    jar = state.jar

    case Operation.fetch_json_api({client, jar}, url) do
      {:ok, {json_body, updated_jar}} ->
        {:reply, {:ok, json_body}, %{client: client, jar: updated_jar}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp sleep_random() do
    if Mix.env() != :test do
      sleep_seconds = @base_sleep_seconds + :rand.uniform(7)
      :timer.sleep(trunc(sleep_seconds * 1000))
    end
  end
end
