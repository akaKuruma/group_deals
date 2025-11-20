defmodule GroupDeals.Gap.DiscountCalculatorTest do
  use ExUnit.Case, async: true

  alias GroupDeals.Gap.DiscountCalculator

  describe "calculate_discounts/1 - Extra X% off pattern" do
    test "extracts 50% discount from 'Extra 50% off'" do
      result = DiscountCalculator.calculate_discounts("Extra 50% off")
      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "extracts 60% discount from 'Extra 60% off'" do
      result = DiscountCalculator.calculate_discounts("Extra 60% off")
      assert result == %{discount: 60, second_discount_percentage: 20}
    end

    test "extracts 70% discount from 'Extra 70% off'" do
      result = DiscountCalculator.calculate_discounts("Extra 70% off")
      assert result == %{discount: 70, second_discount_percentage: 20}
    end

    test "handles 'Extra 50% off. Applied at checkout'" do
      result = DiscountCalculator.calculate_discounts("Extra 50% off. Applied at checkout")
      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "handles 'Final sale. Extra 50% off. Applied at checkout'" do
      result =
        DiscountCalculator.calculate_discounts("Final sale. Extra 50% off. Applied at checkout")

      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "handles case insensitive 'EXTRA 50% OFF'" do
      result = DiscountCalculator.calculate_discounts("EXTRA 50% OFF")
      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "handles case insensitive 'extra 60% off'" do
      result = DiscountCalculator.calculate_discounts("extra 60% off")
      assert result == %{discount: 60, second_discount_percentage: 20}
    end

    test "extracts first percentage when multiple Extra X% off patterns exist" do
      result =
        DiscountCalculator.calculate_discounts("Extra 50% off. Extra 60% off. Applied at checkout")

      # Should extract the first match (50%)
      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "handles extra whitespace in 'Extra  50%  off'" do
      result = DiscountCalculator.calculate_discounts("Extra  50%  off")
      assert result == %{discount: 50, second_discount_percentage: 20}
    end
  end

  describe "calculate_discounts/1 - Friends & Family deal" do
    test "handles 'Friends & Family deal'" do
      result = DiscountCalculator.calculate_discounts("Friends & Family deal")
      assert result == %{discount: 20, second_discount_percentage: 0}
    end

    test "handles 'Friends & Family deal' with additional text" do
      result =
        DiscountCalculator.calculate_discounts("Friends & Family deal. Limited time offer")

      assert result == %{discount: 20, second_discount_percentage: 0}
    end

    test "handles 'Friends & Family deal' in mixed case" do
      # Note: String.contains? is case-sensitive, so this should NOT match
      result = DiscountCalculator.calculate_discounts("friends & family deal")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end
  end

  describe "calculate_discounts/1 - default cases" do
    test "handles 'Featured style! Price as marked'" do
      result = DiscountCalculator.calculate_discounts("Featured style! Price as marked")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles 'Final sale' only" do
      result = DiscountCalculator.calculate_discounts("Final sale")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles arbitrary marketing text" do
      result = DiscountCalculator.calculate_discounts("New arrival! Limited edition")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles text with percentage but not Extra X% off pattern" do
      result = DiscountCalculator.calculate_discounts("Save 50% today")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end
  end

  describe "calculate_discounts/1 - nil and empty values" do
    test "handles nil" do
      result = DiscountCalculator.calculate_discounts(nil)
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles empty string" do
      result = DiscountCalculator.calculate_discounts("")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles 'null' string" do
      result = DiscountCalculator.calculate_discounts("null")
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles non-string values (list)" do
      result = DiscountCalculator.calculate_discounts([1, 2, 3])
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles non-string values (map)" do
      result = DiscountCalculator.calculate_discounts(%{key: "value"})
      assert result == %{discount: 0, second_discount_percentage: 0}
    end

    test "handles non-string values (integer)" do
      result = DiscountCalculator.calculate_discounts(123)
      assert result == %{discount: 0, second_discount_percentage: 0}
    end
  end

  describe "calculate_discounts/1 - combined flags" do
    test "handles multiple flags combined with periods" do
      result =
        DiscountCalculator.calculate_discounts("Final sale. Extra 50% off. Applied at checkout")

      assert result == %{discount: 50, second_discount_percentage: 20}
    end

    test "prioritizes Extra X% off over Friends & Family when both present" do
      result =
        DiscountCalculator.calculate_discounts("Extra 60% off. Friends & Family deal")

      # Extra X% off is checked first, so it should match
      assert result == %{discount: 60, second_discount_percentage: 20}
    end
  end
end
