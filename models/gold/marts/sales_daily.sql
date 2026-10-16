with items as (
    select * from {{ ref('fct_order_items') }}
    where is_valid_sale
)

select
    order_date                                        as sale_date,
    genre,
    count(distinct order_id)                          as orders,
    sum(quantity)                                     as units_sold,
    sum(line_total)                                   as revenue
from items
group by sale_date, genre
order by sale_date, genre
