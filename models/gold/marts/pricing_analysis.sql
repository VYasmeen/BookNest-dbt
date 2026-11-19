with items as (
    select * from {{ ref('fct_order_items') }}
    where is_valid_sale
),
books as (
    select * from {{ ref('dim_books') }}
),
items_priced as (
    select
        items.book_id,
        books.title,
        books.author,
        books.genre,
        books.price_band,
        books.price                                     as list_price,
        items.unit_price,
        items.quantity,
        items.line_total,
        books.price - items.unit_price                 as discount_per_unit,
        (1.0 - items.unit_price / nullif(books.price, 0)) * 100 as discount_percent
    from items
    left join books on items.book_id = books.book_id
)

select
    book_id,
    title,
    author,
    genre,
    price_band,
    list_price,
    round(avg(unit_price), 2)                          as avg_sale_price,
    round(avg(discount_per_unit), 2)                   as avg_discount_per_unit,
    round(avg(discount_percent), 2)                    as avg_discount_percent,
    min(unit_price)                                    as min_sale_price,
    max(unit_price)                                    as max_sale_price,
    count(*)                                           as transaction_count,
    sum(quantity)                                      as units_sold,
    round(sum(line_total), 2)                          as total_revenue
from items_priced
group by book_id, title, author, genre, price_band, list_price
