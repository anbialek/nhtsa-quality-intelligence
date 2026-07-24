with complaints as (
    select * from {{ ref('silver_complaint') }}
),

affected_products as (
    select * from {{ ref('silver_complaint_product') }}
),

manufacturers as (
    select * from {{ ref('dim_manufacturer') }}
),

joined as (
    select
        -- Keys
        sc.odi_number,
        dm.manufacturer_key,
        cast(strftime(sc.date_of_incident, '%Y%m%d') as integer) as incident_date_key,
        cast(strftime(sc.date_complaint_filed, '%Y%m%d') as integer) as filed_date_key,
        
        -- Complaint details
        sc.vin,
        sc.cohort_key,
        sc.date_of_incident,
        sc.date_complaint_filed,
        sc.filing_lag_days,
        sc.components,
        sc.summary,
        sc.crash,
        sc.fire,
        sc.number_of_injuries,
        sc.number_of_deaths,
        
        -- Vehicle product details
        scp.product_make as make,
        scp.product_model as model,
        scp.product_year as model_year,
        scp.product_manufacturer,
        
        -- Audit
        sc.ingested_at
        
    from complaints sc
    left join affected_products scp
        on sc.odi_number = scp.odi_number
    left join manufacturers dm
        on sc.manufacturer = dm.manufacturer_name
)

select * from joined