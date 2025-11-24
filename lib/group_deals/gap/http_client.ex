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
  @spec init(any()) :: {:ok, %{client: Req.Request.t(), jar: any(), session_initialized: boolean()}}
  def init(_opts) do
    client = Operation.create_client()
    jar = Operation.create_jar()

    # Don't create session during init - do it lazily on first request
    # This allows the application to start even if Gap Factory is blocking requests
    {:ok, %{client: client, jar: jar, session_initialized: false}}
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
    state = ensure_session_initialized(state)
    client = state.client
    jar = state.jar

    case Operation.fetch_product_html_page({client, jar}, url) do
      {:ok, {html_body, updated_jar}} ->
        {:reply, {:ok, html_body}, %{state | jar: updated_jar}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:fetch_json_api, url}, _from, state) do
    state = ensure_session_initialized(state)
    client = state.client
    jar = state.jar

    case Operation.fetch_json_api({client, jar}, url) do
      {:ok, {json_body, updated_jar}} ->
        {:reply, {:ok, json_body}, %{state | jar: updated_jar}}

      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end

  defp ensure_session_initialized(%{session_initialized: true} = state), do: state

  defp ensure_session_initialized(state) do
    case Operation.create_session({state.client, state.jar}) do
      {:ok, updated_jar} ->
        Logger.info("Gap HttpClient session initialized successfully")
        %{state | jar: updated_jar, session_initialized: true}

      {:error, reason} ->
        Logger.warning("Failed to initialize Gap HttpClient session: #{inspect(reason)}. Will retry on next request.")
        # Don't fail - session might work on retry or the request might work without it
        state
    end
  end

  defp sleep_random() do
    if Mix.env() != :test do
      sleep_seconds = @base_sleep_seconds + :rand.uniform(7)
      :timer.sleep(trunc(sleep_seconds * 1000))
    end
  end
end
