with staged as (
    select * from {{ref('stg_complaints')}}
),

unnested as (
    select
    odi_number,
    ingested_at,
    unnest(products, recursive := true) as product
    from staged
),

vehicle_only as (
    select
    odi_number,
    ingested_at,
    "type" as product_type,
    cast("productYear" as integer) as product_year,
    "productMake" as product_make,
    "productModel" as product_model,
    manufacturer as product_manufacturer
    from unnested
    where "type" = 'Vehicle'
),

deduplicated as (
    select
    odi_number,
    product_year,
    product_make,
    product_model,
    product_manufacturer,
    ingested_at
    from vehicle_only
    qualify row_number() over (partition by odi_number, product_make, product_model, product_year order by ingested_at desc) = 1
)

select * from deduplicated