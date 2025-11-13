defmodule GroupDeals.Gap.HttpClient.Operation do
  @moduledoc """
  Operations for the Gap HTTP client.
  """

  @gap_factory_homepage "https://www.gapfactory.com/"
  # @gap_factory_api_url "https://api.gapfactory.com/commerce/search/products/v2/cc"

  @headers [
    {"User-Agent",
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"},
    {"Accept-Language", "en-US,en;q=0.9"},
    {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"},
    {"Connection", "keep-alive"},
    {"Referer", "https://www.gapfactory.com/"}
  ]

  @spec create_jar() :: HttpCookie.Jar.t()
  def create_jar(), do: HttpCookie.Jar.new()

  @spec create_client() :: Req.Request.t()
  def create_client() do
    Req.new(headers: @headers, receive_timeout: 30_000, retry: req_retry_strategy())
    |> HttpCookie.ReqPlugin.attach()
  end

  @spec create_session({Req.Request.t(), any()}) ::
          {:error,
           {:http_error, non_neg_integer()}
           | {:request_error,
              %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()}}}
          | {:ok, any()}
  def create_session({client, jar}) do
    case get_page({client, jar}, @gap_factory_homepage) do
      {:ok, {_body, updated_jar}} ->
        {:ok, updated_jar}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Fetches a Product HTML Page from the Gap Factory homepage.
  """
  @spec fetch_product_html_page({Req.Request.t(), any()}, binary()) ::
          {:error,
           {:http_error, non_neg_integer()}
           | {:request_error,
              %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()}}}
          | {:ok, {binary(), any()}}
  def fetch_product_html_page({client, jar}, url), do: get_page({client, jar}, url)

  @doc """
  Fetches a JSON API from the Gap Factory homepage.
  """
  @spec fetch_json_api({Req.Request.t(), any()}, binary()) ::
          {:error,
           {:http_error, non_neg_integer()}
           | {:request_error,
              %{:__exception__ => true, :__struct__ => atom(), optional(atom()) => any()}}}
          | {:ok, {binary(), any()}}
  def fetch_json_api({client, jar}, url), do: get_json_api({client, jar}, url)

  defp get_json_api({client, jar}, url) do
    request = Req.merge(client, url: url, cookie_jar: jar, decode_body: true)

    case Req.get(request) do
      {:ok, %Req.Response{status: status, body: body} = response} when status in 200..299 ->
        updated_jar = response.private[:cookie_jar] || jar
        {:ok, {body, updated_jar}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  defp get_page({client, jar}, url) do
    request = Req.merge(client, url: url, cookie_jar: jar)

    case Req.get(request) do
      {:ok, %Req.Response{status: status, body: body} = response} when status in 200..299 ->
        updated_jar = response.private[:cookie_jar] || jar
        {:ok, {body, updated_jar}}

      {:ok, %Req.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_error, reason}}
    end
  end

  defp req_retry_strategy() do
    if Mix.env() != :test, do: :transient, else: false
  end
end
