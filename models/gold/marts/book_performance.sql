with books as (
    select * from {{ ref('dim_books') }}
),
items as (
    select * from {{ ref('fct_order_items') }}
    where is_valid_sale
),
inventory as (
    select * from {{ ref('fct_inventory_snapshot') }}
    where is_current
),

sold as (
    select
        book_id,
        sum(quantity)                                 as units_sold,
        sum(line_total)                               as revenue
    from items
    group by book_id
)

select
    books.book_id,
    books.title,
    books.author,
    books.genre,
    books.price,
    coalesce(sold.units_sold, 0)                      as units_sold,
    coalesce(sold.revenue, 0)                         as revenue,
    inventory.stock_quantity                          as current_stock,
    inventory.last_restocked_at,
    -- days of stock remaining at the historical sales pace (data window ~638 days)
    case
        when coalesce(sold.units_sold, 0) = 0        then null
        when inventory.stock_quantity is null         then null
        when inventory.stock_quantity <= 0           then 0
        else cast(inventory.stock_quantity as double)
             / (sold.units_sold / 638.0)
    end                                               as days_of_stock_remaining
from books
left join sold      on books.book_id = sold.book_id
left join inventory on books.book_id = inventory.book_id
