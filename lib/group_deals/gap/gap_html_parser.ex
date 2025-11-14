defmodule GroupDeals.Gap.GapHtmlParser do
  @moduledoc """
  Parses HTML product pages to extract product data.

  Extracts sizes, image URL, description, and price similar to the Python scraper.
  """

  alias GroupDeals.Gap.SizeMapper

  @doc """
  Parses HTML content and extracts product data.

  Returns a map with:
  - sizes: list of mapped size IDs (as strings)
  - image_url: product image URL
  - description: product title/description
  - price: product price (as string)
  - available_sizes: comma-separated list of size IDs (for compatibility)
  """
  @spec parse_html(String.t(), integer()) :: map()
  def parse_html(html, id_store_category) do
    html
    |> Floki.parse_document!()
    |> extract_product_data(id_store_category)
  end

  defp extract_product_data(html_tree, id_store_category) do
    %{
      sizes: extract_sizes(html_tree, id_store_category),
      image_url: extract_image_url(html_tree),
      description: extract_description(html_tree),
      price: extract_price(html_tree),
      available_sizes: extract_available_sizes_string(html_tree, id_store_category)
    }
  end

  defp extract_sizes(html_tree, id_store_category) do
    # Find the container that holds the size inputs/labels
    case Floki.find(html_tree, "div.pdp_size-selector-container__items") do
      [] ->
        []

      [container] ->
        # Get all direct children of the container to preserve order
        # This allows us to match inputs with their following labels
        children = Floki.children(container)

        # Process children in order, matching inputs to their following labels
        process_size_children(children, id_store_category, [])

      _ ->
        []
    end
  end

  defp process_size_children([], _id_store_category, acc), do: Enum.reverse(acc)

  defp process_size_children([child | rest], id_store_category, acc) do
    # Check if this child is an input element
    case child do
      {"input", attrs, _} ->
        # Check if it's the right type of input
        type = get_attr(attrs, "type")
        name = get_attr(attrs, "name")
        class = get_attr(attrs, "class") || ""

        if type == "radio" and name == "buybox-sizeDimension1" and
             String.contains?(class, "fds_selector__input") do
          # Check if size is out of stock
          data_testid = String.downcase(get_attr(attrs, "data-testid") || "")
          aria_disabled = String.downcase(get_attr(attrs, "aria-disabled") || "")

          is_out = data_testid == "pdp-dimension-outofstock" or aria_disabled == "true"

          if is_out do
            # Skip this input and its label
            # The label should be the next element
            process_size_children(skip_next_label(rest), id_store_category, acc)
          else
            # Find the next label (should be the next element)
            case find_next_label(rest) do
              nil ->
                process_size_children(rest, id_store_category, acc)

              {label, remaining} ->
                # Extract size text from span
                case Floki.find([label], "span.fds_selector__content") do
                  [] ->
                    process_size_children(remaining, id_store_category, acc)

                  [span] ->
                    size_text = Floki.text(span) |> String.trim()
                    size_lower = String.downcase(size_text)

                    # Filter out unwanted dimension variants
                    if String.contains?(size_lower, "out of stock") or
                         String.contains?(size_lower, "regular") or
                         String.contains?(size_lower, "tall") or
                         String.contains?(size_lower, "petite") do
                      process_size_children(remaining, id_store_category, acc)
                    else
                      # Map size to size ID
                      mapped_size = SizeMapper.map_size(id_store_category, size_text)
                      process_size_children(remaining, id_store_category, [mapped_size | acc])
                    end
                end
            end
          end
        else
          process_size_children(rest, id_store_category, acc)
        end

      _ ->
        # Not an input, continue processing
        process_size_children(rest, id_store_category, acc)
    end
  end

  defp find_next_label([]), do: nil

  defp find_next_label([child | rest]) do
    case child do
      {"label", _, _} -> {child, rest}
      _ -> find_next_label(rest)
    end
  end

  defp skip_next_label([]), do: []

  defp skip_next_label([child | rest]) do
    case child do
      {"label", _, _} -> rest
      _ -> rest
    end
  end

  defp get_attr(attrs, key) do
    Enum.find_value(attrs, fn
      {^key, value} -> value
      _ -> nil
    end)
  end

  defp extract_available_sizes_string(html_tree, id_store_category) do
    extract_sizes(html_tree, id_store_category)
    |> Enum.join(", ")
  end

  defp extract_image_url(html_tree) do
    html_tree
    |> Floki.find("img")
    |> Enum.find_value("", fn img ->
      alt = Floki.attribute(img, "alt") |> List.first() || ""
      alt_lower = String.downcase(alt)

      if String.contains?(alt_lower, "view large product image") or
           String.contains?(alt_lower, "image number") do
        src = Floki.attribute(img, "src") |> List.first() || ""
        data_src = Floki.attribute(img, "data-src") |> List.first() || ""

        image_url = if src != "", do: src, else: data_src

        if String.starts_with?(image_url, "/") do
          "https://www.gapfactory.com" <> image_url
        else
          image_url
        end
      else
        nil
      end
    end)
  end

  defp extract_description(html_tree) do
    html_tree
    |> Floki.find("h1")
    |> Enum.find_value("", fn h1 ->
      class = Floki.attribute(h1, "class") |> List.first() || ""

      if String.contains?(class, "pdp-product-title") do
        Floki.text(h1) |> String.trim()
      else
        nil
      end
    end)
  end

  defp extract_price(html_tree) do
    html_tree
    |> Floki.find("span")
    |> Enum.find_value("", fn span ->
      class = Floki.attribute(span, "class") |> List.first() || ""

      if String.contains?(class, "current-sale-price") do
        raw_price = Floki.text(span) |> String.trim()
        # Remove $ and commas, keep only digits and decimal point
        raw_price
        |> String.replace("$", "")
        |> String.replace(",", "")
        |> String.trim()
      else
        nil
      end
    end)
  end
end
