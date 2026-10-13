{{ config(materialized='table') }}

WITH crops AS (
    SELECT * FROM {{ source('silver', 'crops') }}
)

SELECT 
    harvest_item_name AS crop_name,
    crop_category,
    array_to_string(seasons, ', ') AS seasons_list,
    growth_days,
    crop_sell_price AS raw_sell_price,

    -- 1. KEG (Wine & Juice & Coffee)
    can_make_wine,
    CASE WHEN can_make_wine THEN (crop_sell_price * 3) END AS wine_sell_price,
    CASE WHEN can_make_wine THEN ROUND((((crop_sell_price * 3) - crop_sell_price)::NUMERIC / 10000) * 1600, 2) END AS wine_profit_per_day,

    can_make_juice,
    CASE WHEN can_make_juice THEN (crop_sell_price * 2.25) END AS juice_sell_price,
    CASE WHEN can_make_juice THEN ROUND((((crop_sell_price * 2.25) - crop_sell_price)::NUMERIC / 6000) * 1600, 2) END AS juice_profit_per_day,

    CASE WHEN harvest_item_name = 'Coffee Bean' THEN 150 END AS coffee_sell_price,
    CASE WHEN harvest_item_name = 'Coffee Bean' THEN ROUND(((150 - (crop_sell_price * 5))::NUMERIC / 120) * 1600, 2) END AS coffee_profit_per_day,

    -- 2. PRESERVES JAR (Jelly & Pickles)
    can_make_jelly,
    CASE WHEN can_make_jelly THEN (crop_sell_price * 2) + 50 END AS jelly_sell_price,
    CASE WHEN can_make_jelly THEN ROUND(((((crop_sell_price * 2) + 50) - crop_sell_price)::NUMERIC / 4000) * 1600, 2) END AS jelly_profit_per_day,

    can_make_pickles,
    CASE WHEN can_make_pickles THEN (crop_sell_price * 2) + 50 END AS pickles_sell_price,
    CASE WHEN can_make_pickles THEN ROUND(((((crop_sell_price * 2) + 50) - crop_sell_price)::NUMERIC / 4000) * 1600, 2) END AS pickles_profit_per_day,

    -- 3. DEHYDRATOR (Dried Fruit & Mushrooms)
    can_make_dried_fruit,
    CASE WHEN can_make_dried_fruit THEN (crop_sell_price * 7.5) + 25 END AS dried_fruit_sell_price,
    CASE WHEN can_make_dried_fruit THEN ROUND(((((crop_sell_price * 7.5) + 25) - (crop_sell_price * 5))::NUMERIC / 1600) * 1600, 2) END AS dried_fruit_profit_per_day,

    can_make_dried_mushrooms,
    CASE WHEN can_make_dried_mushrooms THEN (crop_sell_price * 7.5) + 25 END AS dried_mushrooms_sell_price,
    CASE WHEN can_make_dried_mushrooms THEN ROUND(((((crop_sell_price * 7.5) + 25) - (crop_sell_price * 5))::NUMERIC / 1600) * 1600, 2) END AS dried_mushrooms_profit_per_day,

    -- 4. BEE HOUSE (Honey)
    can_make_honey,
    CASE WHEN can_make_honey THEN (crop_sell_price * 2) + 100 END AS flower_honey_sell_price,
    CASE WHEN can_make_honey THEN ROUND(((((crop_sell_price * 2) + 100) - 100)::NUMERIC / (4 * 1600)) * 1600, 2) END AS honey_profit_per_day

FROM crops
WHERE harvest_item_name IS NOT NULL