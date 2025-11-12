defmodule GroupDeals.Gap.ProductUrlBuilder do
  @moduledoc """
  Builds product page URLs for Gap Factory products.
  """

  @default_base_url "https://www.gapfactory.com/browse/product.do"
  @default_vid "1"

  defp base_url do
    Application.get_env(:group_deals, :gap_product_base_url, @default_base_url)
  end

  @doc """
  Builds a product URL from cc_id and GapPage parameters.

  Extracts vid, pcid, cid, and nav from GapPage.web_page_parameters if available.
  Falls back to minimal URL format if parameters are missing.

  ## Examples

      iex> gap_page = %GroupDeals.Gap.GapPage{
      ...>   web_page_parameters: %{
      ...>     "cid" => "1111149",
      ...>     "pcid" => "1111149",
      ...>     "nav" => "meganav:Women:Featured Shops:Logo Shop"
      ...>   }
      ...> }
      iex> ProductUrlBuilder.build_product_url("814031011", gap_page)
      "https://www.gapfactory.com/browse/product.do?pid=814031011&vid=1&pcid=1111149&cid=1111149&nav=meganav%3AWomen%3AFeatured+Shops%3ALogo+Shop#pdp-page-content"

      iex> gap_page = %GroupDeals.Gap.GapPage{web_page_parameters: nil}
      iex> ProductUrlBuilder.build_product_url("814031011", gap_page)
      "https://www.gapfactory.com/browse/product.do?pid=814031011"
  """
  def build_product_url(cc_id, gap_page) do
    params = extract_params(gap_page)

    if has_required_params?(params) do
      build_full_url(cc_id, params)
    else
      build_minimal_url(cc_id)
    end
  end

  defp extract_params(%{web_page_parameters: nil}), do: %{}
  defp extract_params(%{web_page_parameters: params}) when is_map(params), do: params
  defp extract_params(_), do: %{}

  defp has_required_params?(params) do
    Map.has_key?(params, "cid") || Map.has_key?(params, :cid) ||
      Map.has_key?(params, "pcid") || Map.has_key?(params, :pcid)
  end

  defp build_full_url(cc_id, params) do
    vid = get_param(params, "vid", @default_vid)
    cid = get_param(params, "cid") || get_param(params, "pcid")
    pcid = get_param(params, "pcid") || cid
    nav = get_param(params, "nav")

    query_params = [
      {"pid", cc_id},
      {"vid", vid},
      {"pcid", pcid},
      {"cid", cid}
    ]

    query_params = if nav, do: query_params ++ [{"nav", nav}], else: query_params

    query_string = URI.encode_query(query_params)
    "#{base_url()}?#{query_string}#pdp-page-content"
  end

  defp build_minimal_url(cc_id) do
    "#{base_url()}?pid=#{cc_id}"
  end

  defp get_param(params, key, default \\ nil) do
    Map.get(params, key) || Map.get(params, String.to_atom(key)) || default
  end
end
