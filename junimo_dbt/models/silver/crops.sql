{{ config(materialized='table') }}

-- 1. Extract and clean data from source 1
WITH crops_stardew_data AS (
    SELECT 
        item->>'seedId'                                      AS seed_id,
        item->>'name'                                        AS harvest_item_name,
        item->>'harvestItemId'                               AS harvest_item_id,
        ARRAY (
            SELECT jsonb_array_elements_text(item->'seasons')
        )                                                    AS seasons,
        (item->>'growthDays')::INT                           AS growth_days,
        (item->>'regrowDays')::INT                           AS regrow_days,
        (item->>'sellPrice')::INT                            AS crop_sell_price,
        (item->>'minHarvest')::INT                           AS min_harvest,
        (item->>'maxHarvest')::INT                           AS max_harvest,
        item->>'harvestMethod'                               AS crop_harvest_method,
        item->>'ccBundle'                                    AS cc_bundle
    FROM {{ source('bronze', 'crops_stardew_data') }},
    LATERAL jsonb_array_elements((payload->0)->'crops')      AS item
),

-- 2. Extract and clean data from source 2
crops_stardew_valley_data AS (
    SELECT 
        item->>'seedId'                                      AS seed_id,
        item->>'seedName'                                    AS seed_name,
        item->>'harvestItemId'                               AS harvest_item_id,
        item->>'name'                                        AS harvest_item_name,
        ARRAY (
            SELECT jsonb_array_elements_text(item->'seasons')
        )                                                    AS seasons,
        (item->>'growthDays')::INT                           AS growth_days,
        (item->>'regrowDays')::INT                           AS regrow_days,
        (item->>'cropSellPrice')::INT                        AS crop_sell_price,
        (item->>'seedSellPrice')::INT                        AS seed_sell_price,
        -- Pierre's
        (
            SELECT (p->>'price')::INT 
            FROM jsonb_array_elements(item->'seedBuyPrices') AS p 
            WHERE p->>'place' = 'Pierre''s'
            LIMIT 1
        )                                                    AS pierre_price,
        -- JojaMart
        (
            SELECT (p->>'price')::INT 
            FROM jsonb_array_elements(item->'seedBuyPrices') AS p 
            WHERE p->>'place' = 'JojaMart'
            LIMIT 1
        )                                                    AS jojamart_price,
        -- Oasis
        (
            SELECT (p->>'price')::INT 
            FROM jsonb_array_elements(item->'seedBuyPrices') AS p 
            WHERE p->>'place' = 'Oasis'
            LIMIT 1
        )                                                    AS oasis_price,
        -- Traveling Cart
        (
            SELECT (p->>'price')::INT 
            FROM jsonb_array_elements(item->'seedBuyPrices') AS p 
            WHERE p->>'place' = 'Traveling Cart'
            LIMIT 1
        )                                                    AS traveling_cart_price,
        -- Egg Festival
        (
            SELECT (p->>'price')::INT 
            FROM jsonb_array_elements(item->'seedBuyPrices') AS p 
            WHERE p->>'place' = 'Egg Festival'
            LIMIT 1
        )                                                    AS egg_festival_price,
        item->'seedBuyPrices'                                AS seed_buy_prices_raw,
        item->'category'                                     AS crop_category,
        ((item->'harvestQuantity')->>'min')::INT             AS min_harvest,
        ((item->'harvestQuantity')->>'max')::INT             AS max_harvest,
        (item->'trellis')::BOOLEAN                           AS is_trellis,
        (item->'giant')::BOOLEAN                             AS can_giant,
        item->'description' AS crop_description,
        ((item->'energyHealth')->>'energy')::INT             AS energy_gain,
        ((item->'energyHealth')->>'health')::INT             AS health_gain,
        (item->'farmingXP')::INT                             AS farming_xp,
        item->'maxQuality'                                   AS max_quality,
        -- artisan_uses
        ((item->'artisanUses')->>'wine')::BOOLEAN            AS can_make_wine,
        ((item->'artisanUses')->>'honey')::BOOLEAN           AS can_make_honey,
        ((item->'artisanUses')->>'jelly')::BOOLEAN           AS can_make_jelly,
        ((item->'artisanUses')->>'juice')::BOOLEAN           AS can_make_juice,
        ((item->'artisanUses')->>'pickles')::BOOLEAN         AS can_make_pickles,
        ((item->'artisanUses')->>'driedFruit')::BOOLEAN      AS can_make_dried_fruit,
        ((item->'artisanUses')->>'driedMushrooms')::BOOLEAN  AS can_make_dried_mushrooms
    FROM {{ source('bronze', 'crops_stardew_valley_data') }},
    LATERAL jsonb_array_elements(payload)                    AS item
)

-- 3. Combine both sources
SELECT
    -- Primary Key / use_primary
    COALESCE(a.seed_id, b.seed_id)                                AS seed_id,

    -- Secondary (use_secondary)
    b.seed_name                                                   AS seed_name,

    -- Primary (use_primary)
    COALESCE(a.harvest_item_id, b.harvest_item_id)                AS harvest_item_id,
    COALESCE(a.harvest_item_name, b.harvest_item_name)            AS harvest_item_name,
    COALESCE(a.seasons, b.seasons)                                AS seasons,
    COALESCE(a.growth_days, b.growth_days)                        AS growth_days,
    COALESCE(a.regrow_days, b.regrow_days)                        AS regrow_days,
    COALESCE(a.crop_sell_price, b.crop_sell_price)                AS crop_sell_price,

    -- Secondary (use_secondary)
    b.seed_sell_price                                             AS seed_sell_price,
    b.pierre_price                                                AS pierre_price,
    b.jojamart_price                                              AS jojamart_price,
    b.oasis_price                                                 AS oasis_price,
    b.traveling_cart_price                                        AS traveling_cart_price,
    b.egg_festival_price                                          AS egg_festival_price,
    b.seed_buy_prices_raw                                         AS seed_buy_prices,
    b.crop_category                                               AS crop_category,

    -- Primary (use_primary)
    COALESCE(a.min_harvest, b.min_harvest)                        AS min_harvest,
    COALESCE(a.max_harvest, b.max_harvest)                        AS max_harvest,

    -- Secondary (use_secondary)
    b.is_trellis                                                  AS is_trellis,
    b.can_giant                                                   AS can_giant,
    b.crop_description                                            AS crop_description,
    b.energy_gain                                                 AS energy_gain,
    b.health_gain                                                 AS health_gain,
    b.farming_xp                                                  AS farming_xp,
    b.max_quality                                                 AS max_quality,

    -- Artisan Uses (use_secondary)
    b.can_make_wine                                               AS can_make_wine,
    b.can_make_honey                                              AS can_make_honey,
    b.can_make_jelly                                              AS can_make_jelly,
    b.can_make_juice                                              AS can_make_juice,
    b.can_make_pickles                                            AS can_make_pickles,
    b.can_make_dried_fruit                                        AS can_make_dried_fruit,
    b.can_make_dried_mushrooms                                    AS can_make_dried_mushrooms,

    -- Primary (use_primary)
    a.crop_harvest_method                                         AS crop_harvest_method,
    a.cc_bundle                                                   AS cc_bundle,

    -- System & Lineage Metadata (Silver)
    CURRENT_TIMESTAMP AT TIME ZONE 'UTC'                          AS _dbt_updated_at,
    CASE 
        WHEN a.seed_id IS NOT NULL AND b.seed_id IS NOT NULL THEN 'stardew-data + stardew-valley-data'
        WHEN a.seed_id IS NOT NULL THEN 'stardew-data'
        ELSE 'stardew-valley-data'
    END                                                           AS _primary_source,
    (a.seed_id IS NOT NULL AND b.seed_id IS NOT NULL)             AS _is_merged

FROM crops_stardew_data AS a
FULL OUTER JOIN crops_stardew_valley_data AS b 
    ON a.seed_id = b.seed_id