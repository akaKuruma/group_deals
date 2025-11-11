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

  @doc """
  Fetches JSON from the Gap API with retry logic.

  Returns `{:ok, json_body}` on success or `{:error, reason}` on failure.
  """
  def fetch_api_json(url) do
    fetch_with_retry(url, 1)
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
