with items as (
    select * from {{ ref('stg_order_items') }}
),
orders as (
    select * from {{ ref('stg_orders') }}
),
books as (
    select * from {{ ref('stg_books') }}
)

select
    items.order_item_id,
    items.order_id,
    items.book_id,
    orders.customer_id,
    orders.order_date,
    orders.status                                  as order_status,
    books.genre,
    books.author,
    items.quantity,
    items.unit_price,
    items.quantity * items.unit_price              as line_total,
    case
        when orders.order_id    is null then false
        when books.book_id      is null then false
        when items.has_invalid_quantity           then false
        when items.has_zero_price                 then false
        when orders.status in ('cancelled','returned') then false
        else true
    end                                            as is_valid_sale
from items
left join orders on items.order_id = orders.order_id
left join books  on items.book_id  = books.book_id
