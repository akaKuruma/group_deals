defmodule GroupDeals.Gap.DiscountCalculator do
  # TODO: Review these discounts; it's possible that they are not correct.
  # Ref: 4_download_img_plus_info_gen_sql.py

  @moduledoc """
  Calculates discount and second_discount_percentage from marketing_flag.

  Based on the logic from the Python script 4_download_img_plus_info_gen_sql.py
  """

  @doc """
  Calculates discount and second_discount_percentage from marketing_flag.

  Returns a map with :discount and :second_discount_percentage.
  """
  @spec calculate_discounts(String.t() | nil) :: %{
          discount: integer(),
          second_discount_percentage: integer()
        }
  def calculate_discounts(nil), do: %{discount: 0, second_discount_percentage: 0}
  def calculate_discounts(""), do: %{discount: 0, second_discount_percentage: 0}
  def calculate_discounts("null"), do: %{discount: 0, second_discount_percentage: 0}

  def calculate_discounts(marketing_flag) when is_binary(marketing_flag) do
    cond do
      # Check for "Extra X% off" pattern (e.g., "Extra 50% off", "Extra 60% off")
      Regex.match?(~r/Extra\s+(\d+)%\s+off/i, marketing_flag) ->
        # Extract the percentage number
        case Regex.run(~r/Extra\s+(\d+)%\s+off/i, marketing_flag) do
          [_, percentage_str] ->
            discount = String.to_integer(percentage_str)
            %{discount: discount, second_discount_percentage: 20}

          _ ->
            %{discount: 0, second_discount_percentage: 0}
        end

      # Check for "Friends & Family deal"
      String.contains?(marketing_flag, "Friends & Family deal") ->
        %{discount: 20, second_discount_percentage: 0}

      # Default case
      true ->
        %{discount: 0, second_discount_percentage: 0}
    end
  end

  def calculate_discounts(_), do: %{discount: 0, second_discount_percentage: 0}
end
