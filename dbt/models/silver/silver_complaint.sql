with staged as (
    select * from {{ ref('stg_complaints') }}
),

cleaned as (
    select
        odi_number,
        manufacturer,
        upper(vin) as vin,
        case when date_of_incident = '1969-12-31' then null else date_of_incident 
        end as date_of_incident,
        date_complaint_filed,
        case when date_of_incident = '1969-12-31' then null else date_diff('day', date_of_incident, date_complaint_filed) 
        end as filing_lag_days,
        components,
        summary,
        crash,
        fire,
        number_of_injuries,
        number_of_deaths,
        ingested_at
    from staged
),

deduplicated as (
    select *
    from cleaned
    qualify row_number() over (partition by odi_number order by ingested_at desc) = 1
)

select * from deduplicated