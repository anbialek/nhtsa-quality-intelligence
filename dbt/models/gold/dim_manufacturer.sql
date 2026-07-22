with recalls_manufacturers as (
    select distinct manufacturer as manufacturer_name
    from {{ref('silver_recall_campaign')}}
    where manufacturer is not null
),

complaint_manufacturers as (
    select distinct manufacturer as manufacturer_name
    from {{ref('silver_complaint')}}
    where manufacturer is not null
),

combined as (
    select manufacturer_name from recalls_manufacturers
    union 
    select manufacturer_name from complaint_manufacturers
),

final as (
    select
        row_number() over (order by manufacturer_name) as manufacturer_key,
        manufacturer_name
    from combined
)

select * from final
