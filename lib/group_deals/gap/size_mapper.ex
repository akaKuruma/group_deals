defmodule GroupDeals.Gap.SizeMapper do
  @moduledoc """
  Maps size labels to size IDs based on store category.

  Size maps are based on the Python scraper implementation.
  """

  @womens_map %{
    "XXS" => 368,
    "XS" => 369,
    "S" => 370,
    "M" => 371,
    "L" => 372,
    "XL" => 373,
    "XXL" => 374,
    "S/M" => 9172,
    "M/L" => 9173,
    "L/XL" => 9174
  }

  @mens_map %{
    "XS" => 354,
    "S" => 355,
    "M" => 356,
    "L" => 357,
    "XL" => 358,
    "XXL" => 359,
    "XXXL" => 360
  }

  @kids_girls_map %{
    "XS (4/5)" => 1843,
    "S (6/7)" => 1844,
    "M (8)" => 1845,
    "L (10)" => 1846,
    "XL (12)" => 1847,
    "XXL (14/16)" => 1848,
    "XXXL (18)" => 8016,
    "XS/S" => 11826,
    "S/M" => 1849,
    "M/L" => 9175,
    "L/XL" => 1849,
    "6-12 M" => 8722,
    "12-18 M" => 8723,
    "18-24 M" => 8724,
    "2 YRS" => 5119,
    "3 YRS" => 5120,
    "4 YRS" => 5121,
    "5 YRS" => 2364,
    "6 YRS" => 2365,
    "7 YRS" => 2366,
    "8 YRS" => 2367,
    "10 YRS" => 2368,
    "4" => 4855,
    "5" => 4856,
    "6" => 4857,
    "7" => 4858,
    "8" => 4828,
    "10" => 4829,
    "12" => 4830,
    "14" => 4859
  }

  @kids_boys_map %{
    "XS (4/5)" => 342,
    "S (6/7)" => 343,
    "M (8)" => 344,
    "L (10)" => 345,
    "XL (12)" => 346,
    "XXL (14/16)" => 347,
    "XXXL (18)" => 8018,
    "XS" => 11823,
    "S" => 10081,
    "M" => 10082,
    "L" => 10083,
    "XL" => 10084,
    "XXL" => 11824,
    "XS/S" => 11825,
    "S/M" => 348,
    "L/XL" => 349,
    "6-12 M" => 8728,
    "12-18 M" => 8729,
    "18-24 M" => 8730,
    "2 YRS" => 8731,
    "3 YRS" => 8732,
    "4 YRS" => 8733,
    "5 YRS" => 2372,
    "6 YRS" => 2373,
    "7 YRS" => 2374,
    "8 YRS" => 322,
    "10 YRS" => 323,
    "4" => 8733,
    "6" => 2373,
    "8" => 322,
    "10" => 323,
    "12" => 324,
    "14" => 2375,
    "1/2" => 350,
    "3/4" => 351,
    "10/11" => 352,
    "12/13" => 353
  }

  @baby_girl_map %{
    "Up To 7lb" => 4481,
    "0-3 M" => 1830,
    "3-6 M" => 1831,
    "6-12 M" => 1832,
    "6-9 M" => 1842,
    "12-18 M" => 1833,
    "18-24 M" => 1834,
    "2 YRS" => 4415,
    "3 YRS" => 4416,
    "4 YRS" => 4417,
    "5 YRS" => 4418,
    "6 YRS" => 8023,
    "7 YRS" => 8024,
    "8 YRS" => 8025,
    "9 YRS" => 8654,
    "10 YRS" => 8655,
    "0-6 M" => 8042,
    "12-24 M" => 4853,
    "2-3 YRS" => 10038,
    "4-5 YRS" => 10039,
    "XS/S" => 9800,
    "S/M" => 9801,
    "M/L" => 9802
  }

  @baby_boy_map %{
    "Up To 7lb" => 4432,
    "0-3 M" => 311,
    "3-6 M" => 312,
    "6-12 M" => 313,
    "6-9 M" => 1738,
    "12-18 M" => 314,
    "18-24 M" => 315,
    "2 YRS" => 4428,
    "3 YRS" => 4429,
    "4 YRS" => 4430,
    "5 YRS" => 4431,
    "6 YRS" => 1454,
    "8 YRS" => 5126,
    "10 YRS" => 5128,
    "0-6 M" => 8043,
    "12-24 M" => 4420,
    "2-3 YRS" => 4421,
    "4-5 YRS" => 4422,
    "XS/S" => 328,
    "S/M" => 329,
    "M/L" => 327
  }

  @toddler_girls_map %{
    "0-3 M" => 1855,
    "0-6 M" => 1860,
    "3-6 M" => 1856,
    "6-12 M" => 1857,
    "12-18 M" => 1858,
    "12-24 M" => 1861,
    "18-24 M" => 1859,
    "2 YRS" => 8019,
    "2-3 YRS" => 1862,
    "3 YRS" => 8020,
    "4 YRS" => 8021,
    "4-5 YRS" => 1863,
    "5 YRS" => 8022,
    "6 YRS" => 8026,
    "7 YRS" => 8027,
    "8 YRS" => 8028
  }

  @toddler_boys_map %{
    "0-3 M" => 330,
    "0-6 M" => 335,
    "3-6 M" => 331,
    "6-12 M" => 332,
    "12-18 M" => 333,
    "12-24 M" => 336,
    "18-24 M" => 334,
    "2 YRS" => 8035,
    "2-3 YRS" => 337,
    "3 YRS" => 8036,
    "4 YRS" => 8037,
    "4-5 YRS" => 338,
    "5 YRS" => 8038,
    "6 YRS" => 8039,
    "7 YRS" => 8040,
    "8 YRS" => 8041
  }

  @size_maps %{
    5 => @womens_map,
    4 => @mens_map,
    253 => @kids_girls_map,
    67 => @kids_boys_map,
    255 => @baby_girl_map,
    10 => @baby_boy_map,
    254 => @toddler_girls_map,
    68 => @toddler_boys_map
  }

  @doc """
  Gets the size map for a given store category ID.

  Returns the size map or nil if category not found.
  """
  @spec get_size_map(integer()) :: map() | nil
  def get_size_map(id_store_category) do
    Map.get(@size_maps, id_store_category)
  end

  @doc """
  Maps a size label to a size ID based on the store category.

  Returns the size ID as a string, or the original size label if not found.
  """
  @spec map_size(integer(), String.t()) :: String.t()
  def map_size(id_store_category, size_label) do
    case get_size_map(id_store_category) do
      nil ->
        size_label

      size_map ->
        case Map.get(size_map, size_label) do
          nil -> size_label
          size_id -> Integer.to_string(size_id)
        end
    end
  end
end
