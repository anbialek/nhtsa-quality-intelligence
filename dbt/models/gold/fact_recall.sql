with campaigns as (
    select * from {{ ref('silver_recall_campaign') }}
),

affected_models as (
    select * from {{ ref('silver_recall_affected_model') }}
),

manufacturers as (
    select * from {{ ref('dim_manufacturer') }}
),

joined as (
    select
        -- Keys
        am.campaign_number,
        dm.manufacturer_key,
        cast(strftime(c.report_received_date, '%Y%m%d') as integer) as report_date_key,
        
        -- Vehicle dimensions
        am.make,
        am.model,
        am.model_year,
        
        -- Campaign details
        c.component,
        c.summary,
        c.consequence,
        c.remedy,
        
        -- Severity flags
        c.park_it,
        c.park_outside,
        c.over_the_air_update,
        
        -- Audit
        c.ingested_at
    from affected_models am
    left join campaigns c
        on am.campaign_number = c.campaign_number
    left join manufacturers dm
        on c.manufacturer = dm.manufacturer_name
)

select * from joined