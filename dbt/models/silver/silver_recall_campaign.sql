with staged as (
    select *  from {{ref('stg_recalls')}}
),

deduplicated as (
    select
    campaign_number,
    action_number,
    manufacturer,
    report_received_date,
    component,
    summary,
    consequence,
    remedy,
    notes,
    park_it,
    park_outside,
    over_the_air_update,
    ingested_at
from staged
qualify row_number() over (partition by campaign_number order by ingested_at desc) = 1
)

select * from deduplicated