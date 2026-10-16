with date_spine as (
    select unnest(
        generate_series(
            date '2023-01-01',
            date '2026-12-31',
            interval 1 day
        )
    )::date as date_day
)

select
    date_day,
    extract(year    from date_day)                 as year,
    extract(quarter from date_day)                 as quarter,
    extract(month   from date_day)                 as month,
    extract(day     from date_day)                 as day,
    extract(dow     from date_day)                 as day_of_week,
    extract(doy     from date_day)                 as day_of_year,
    extract(week    from date_day)                 as week_of_year,
    strftime(date_day, '%A')                       as day_name,
    strftime(date_day, '%B')                       as month_name,
    case when extract(dow from date_day) in (0, 6)
         then true else false end                  as is_weekend,
    date_trunc('month',   date_day)::date          as month_start,
    date_trunc('quarter', date_day)::date          as quarter_start,
    date_trunc('year',    date_day)::date          as year_start
from date_spine
