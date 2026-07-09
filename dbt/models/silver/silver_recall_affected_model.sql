with staged as (
    select * from {{ref('stg_recalls')}}
),

deduplicated as (
    select
    campaign_number,
    make,
    model,
    model_year,
    ingested_at
    from staged
    qualify row_number() over (partition by campaign_number, make, model, model_year order by ingested_at desc) = 1
)

select * from deduplicated