defmodule GroupDeals.Gap.ApiClient do
  @moduledoc """
  Client for making HTTP requests to Gap API with retry logic and proper headers.
  """

  @max_retries 3
  @base_sleep_seconds 2

  @headers [
    {"User-Agent",
     "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"},
    {"Accept-Language", "en-US,en;q=0.9"},
    {"Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"},
    {"Connection", "keep-alive"},
    {"Referer", "https://www.gapfactory.com/"}
  ]

  @gap_homepage "https://www.gapfactory.com/"

  @doc """
  Fetches JSON from the Gap API with retry logic.

  Returns `{:ok, json_body}` on success or `{:error, reason}` on failure.
  """
  def fetch_api_json(url) do
    fetch_with_retry(url, 1)
  end

  @doc """
  Fetches HTML from a product page URL with retry logic.
  Establishes a session first by visiting the homepage to get cookies,
  then fetches the product page using the same client to maintain cookies.

  Returns `{:ok, html_string}` on success or `{:error, reason}` on failure.
  """
  def fetch_product_html(url) do
    # Create a cookie jar to store cookies
    jar = HttpCookie.Jar.new()

    # Create a Req client with HttpCookie plugin attached
    client =
      Req.new(
        base_url: "https://www.gapfactory.com",
        headers: @headers,
        receive_timeout: 30_000
      )
      |> HttpCookie.ReqPlugin.attach()

    # First, establish a session by visiting the homepage
    # This will set cookies that Gap requires
    with {:ok, updated_jar} <- ensure_session(client, jar),
         {:ok, html} <- fetch_html_with_retry(client, updated_jar, url, 1) do
      {:ok, html}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp fetch_with_retry(_url, attempt) when attempt > @max_retries do
    {:error, :max_retries_exceeded}
  end

  defp fetch_with_retry(url, attempt) do
    case do_fetch(url) do
      {:ok, body} ->
        # Sleep after successful request (2 + random(0-1) seconds)
        sleep_random()
        {:ok, body}

      {:error, reason} ->
        if attempt < @max_retries do
          # Sleep before retry (2 + random(0-1) seconds)
          sleep_random()
          fetch_with_retry(url, attempt + 1)
        else
          {:error, reason}
        end
    end
  end

  defp fetch_html_with_retry(_client, _jar, _url, attempt) when attempt > @max_retries do
    {:error, :max_retries_exceeded}
  end

  defp fetch_html_with_retry(client, jar, url, attempt) do
    case do_fetch_html(client, jar, url) do
      {:ok, html, _updated_jar} ->
        # Sleep after successful request (2 + random(0-1) seconds)
        sleep_random()
        {:ok, html}

      {:error, reason} ->
        if attempt < @max_retries do
          # Sleep before retry (2 + random(0-1) seconds)
          sleep_random()
          fetch_html_with_retry(client, jar, url, attempt + 1)
        else
          {:error, reason}
        end
    end
  end

  defp do_fetch(url) do
    try do
      case Req.get(url, headers: @headers, receive_timeout: 30_000, retry: req_retry_opts()) do
        {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
          # Body might be a string (if decode_json: false) or already decoded map
          case body do
            map when is_map(map) ->
              {:ok, map}

            string when is_binary(string) ->
              case Jason.decode(string) do
                {:ok, json} -> {:ok, json}
                {:error, reason} -> {:error, {:json_decode_error, reason}}
              end

            other ->
              {:error, {:invalid_body_type, other}}
          end

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, reason} ->
          {:error, {:request_error, reason}}
      end
    rescue
      e -> {:error, {:exception, Exception.message(e)}}
    catch
      :exit, reason -> {:error, {:exit, reason}}
    end
  end

  defp ensure_session(client, jar) do
    try do
      # Visit homepage to establish session and get cookies
      # HttpCookie plugin will automatically handle cookies
      request =
        Req.merge(client,
          url: @gap_homepage,
          decode_body: false,
          cookie_jar: jar
        )

      case Req.get(request) do
        {:ok, %Req.Response{status: status} = response} when status in 200..299 ->
          # HttpCookie plugin automatically updates the jar
          # Extract the updated jar from the response
          updated_jar = response.private[:cookie_jar] || jar
          {:ok, updated_jar}

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, reason} ->
          {:error, {:session_failed, reason}}
      end
    rescue
      e -> {:error, {:exception, Exception.message(e)}}
    catch
      :exit, reason -> {:error, {:exit, reason}}
    end
  end

  defp do_fetch_html(client, jar, url) do
    try do
      # HttpCookie plugin will automatically add cookies from the jar to the request
      # and update the jar with any new cookies from the response
      request =
        Req.merge(client,
          url: url,
          decode_body: false,
          cookie_jar: jar
        )

      case Req.get(request) do
        {:ok, %Req.Response{status: status, body: body} = response} when status in 200..299 ->
          # Extract the updated jar from the response
          updated_jar = response.private[:cookie_jar] || jar

          case body do
            string when is_binary(string) ->
              {:ok, string, updated_jar}

            other ->
              {:error, {:invalid_body_type, other}}
          end

        {:ok, %Req.Response{status: status}} ->
          {:error, {:http_error, status}}

        {:error, reason} ->
          {:error, {:request_error, reason}}
      end
    rescue
      e -> {:error, {:exception, Exception.message(e)}}
    catch
      :exit, reason -> {:error, {:exit, reason}}
    end
  end

  defp sleep_random do
    if Mix.env() != :test do
      sleep_seconds = @base_sleep_seconds + :rand.uniform()
      :timer.sleep(trunc(sleep_seconds * 1000))
    end
  end

  defp req_retry_opts do
    retry_fn = fn _, _ -> true end

    if Mix.env() != :test, do: retry_fn, else: false
  end
end
