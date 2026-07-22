with date_spine as (
    select 
        unnest(generate_series(
            '2018-01-01'::date,
            '2028-12-31'::date,
            interval '1 day')) as date_day
),
    
final as (
    select
        cast(strftime(date_day, '%Y%m%d') as integer) as date_key,
        date_day as full_date,
        extract(year from date_day) as year,
        extract(month from date_day) as month,
        extract(day from date_day) as day,
        extract(quarter from date_day) as quarter,
        extract(dayofweek from date_day) as day_of_week,
        dayname(date_day) as day_name,
        monthname(date_day) as month_name,
        case when extract(dayofweek from date_day) in (0, 6) then true else false end as is_weekend
    from date_spine
)

select * from final