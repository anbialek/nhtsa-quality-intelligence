{{ config(severity = 'warn') }}

select
sc.odi_number,
sc.date_of_incident,
scp.product_year,
scp.product_make,
scp.product_model
from {{ref('silver_complaint')}} sc
join {{ref('silver_complaint_product')}} scp
    on sc.odi_number = scp.odi_number
where sc.date_of_incident < make_date(scp.product_year - 1, 1, 1)