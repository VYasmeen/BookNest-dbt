with current_inv as (
    select * from {{ ref('fct_inventory_snapshot') }}
    where is_current
),
sales as (
    select
        book_id,
        sum(quantity)                                  as units_sold,
        min(order_date)                                as first_sale_date,
        max(order_date)                                as last_sale_date,
        count(distinct order_id)                       as orders_with_sales
    from {{ ref('fct_order_items') }}
    where is_valid_sale
    group by book_id
),
books as (
    select * from {{ ref('dim_books') }}
),
date_range as (
    select
        min(date_day)                                  as min_date,
        max(date_day)                                  as max_date
    from {{ ref('dim_date') }}
),
metrics as (
    select
        books.book_id,
        books.title,
        books.genre,
        books.price_band,
        current_inv.stock_quantity,
        current_inv.last_restocked_at,
        coalesce(sales.units_sold, 0)                 as units_sold_all_time,
        sales.first_sale_date,
        sales.last_sale_date,
        sales.orders_with_sales,
        (select max_date from date_range) - (select min_date from date_range) + 1 as days_in_data_window,
        case
            when coalesce(sales.units_sold, 0) = 0 then null
            else round(
                cast(coalesce(sales.units_sold, 0) as float) /
                ((select max_date from date_range) - (select min_date from date_range) + 1) * 365
            , 2)
        end                                            as annual_turnover_rate,
        case
            when coalesce(sales.units_sold, 0) = 0 then null
            else round(
                cast(current_inv.stock_quantity as float) /
                (cast(coalesce(sales.units_sold, 0) as float) /
                ((select max_date from date_range) - (select min_date from date_range) + 1)),
                2
            )
        end                                            as days_on_hand,
        case
            when coalesce(sales.units_sold, 0) = 0 then 'no_sales'
            when sales.last_sale_date < current_date - interval 90 day then 'aged_no_recent_sales'
            when current_inv.stock_quantity = 0 then 'out_of_stock'
            when current_inv.stock_quantity < 5 then 'critical'
            when current_inv.stock_quantity < 20 then 'low'
            else 'healthy'
        end                                            as inventory_health_status
    from books
    left join current_inv on books.book_id = current_inv.book_id
    left join sales on books.book_id = sales.book_id
)

select * from metrics
