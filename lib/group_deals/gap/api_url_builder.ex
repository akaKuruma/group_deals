defmodule GroupDeals.Gap.ApiUrlBuilder do
  alias GroupDeals.Gap.GapPage
  alias Ecto.Changeset

  @base_url "https://api.gapfactory.com/commerce/search/products/v2/cc"
  @default_parameters %{
    "pageSize" => "200",
    "ignoreInventory" => "false",
    "vendor" => "constructorio",
    "client_id" => "0",
    "session_id" => "0",
    "includeMarketingFlagsDetails" => "true",
    "enableDynamicPhoto" => "true",
    "brand" => "gapfs",
    "locale" => "en_US",
    "market" => "us",
    "pageNumber" => "0",
  }

  def build_api_url(%Ecto.Changeset{data: %GapPage{}} = gap_page_changeset) do
    case Changeset.get_field(gap_page_changeset, :web_page_url) do
      url when not is_nil(url) ->
        gap_page_changeset
        |> extract_web_page_parameters()
        |> add_default_parameters()
        |> build_api_url_from_params()
      _ ->
        gap_page_changeset
    end
  end

  defp extract_web_page_parameters(gap_page_changeset) do
    case Changeset.get_field(gap_page_changeset, :web_page_parameters) do
      url_params when not is_nil(url_params) ->
        %{}
        |> extract_cid(url_params)
        |> extract_department(url_params)
      _ ->
        %{}
    end
  end

  defp extract_cid(params, url_params) do
    cid = Map.get(url_params, "cid") || Map.get(url_params, :cid)
    if cid, do: Map.put(params, "cid", cid), else: params
  end

  defp extract_department(params, url_params) do
    department = Map.get(url_params, "department") || Map.get(url_params, :department)
    if department, do: Map.put(params, "department", department), else: params
  end

  defp add_default_parameters(params) do
    Map.merge(params, @default_parameters)
  end

  defp build_api_url_from_params(params) do
    query_string = URI.encode_query(params)
    "#{@base_url}?#{query_string}"
  end
end
