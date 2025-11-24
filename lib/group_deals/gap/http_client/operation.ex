defmodule GroupDeals.Gap.HttpClient.Operation do
  @moduledoc """
  Operations for the Gap HTTP client.
  """

  @gap_factory_homepage "https://www.gapfactory.com/"

  # Base headers shared by all requests
  @base_headers [
    {"User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/142.0.0.0 Safari/537.36"},
    {"Accept-Language", "en-US,en;q=0.9"},
    {"Accept-Encoding", "gzip, deflate, br, zstd"},
    {"Connection", "keep-alive"},
    {"Referer", "https://www.gapfactory.com/"},
    {"sec-ch-ua", "\"Not_A Brand\";v=\"99\", \"Chromium\";v=\"142\""},
    {"sec-ch-ua-mobile", "?0"},
    {"sec-ch-ua-platform", "\"Linux\""}
  ]

  # Headers for HTML page requests
  @html_headers @base_headers ++ [
    {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"},
    {"Sec-Fetch-Dest", "document"},
    {"Sec-Fetch-Mode", "navigate"},
    {"Sec-Fetch-Site", "same-origin"},
    {"Sec-Fetch-User", "?1"},
    {"Upgrade-Insecure-Requests", "1"},
    {"priority", "u=0, i"}
  ]

  # Headers for JSON API requests
  @json_api_headers @base_headers ++ [
    {"Accept", "application/json"},
    {"Content-Type", "application/json"},
    {"Origin", "https://www.gapfactory.com"},
    {"Sec-Fetch-Dest", "empty"},
    {"Sec-Fetch-Mode", "cors"},
    {"Sec-Fetch-Site", "same-site"},
    {"x-client-app-name", "ecom-next"},
    {"priority", "u=1, i"}
  ]

  @spec create_jar() :: HttpCookie.Jar.t()
  def create_jar(), do: HttpCookie.Jar.new()

  @spec create_client() :: Req.Request.t()
  def create_client() do
    # Use HTML headers for session initialization (visiting homepage)
    Req.new(headers: @html_headers, receive_timeout: 30_000, retry: req_retry_strategy())
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
    # Use JSON API specific headers
    request = Req.merge(client, url: url, cookie_jar: jar, decode_body: true, headers: @json_api_headers)

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
    # Use HTML page specific headers
    request = Req.merge(client, url: url, cookie_jar: jar, headers: @html_headers)

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
