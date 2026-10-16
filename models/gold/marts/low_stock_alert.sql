with current_inventory as (
    select * from {{ ref('fct_inventory_snapshot') }}
    where is_current
),
books as (
    select * from {{ ref('dim_books') }}
)

select
    current_inventory.book_id,
    books.title,
    books.author,
    books.genre,
    current_inventory.stock_quantity,
    current_inventory.last_restocked_at,
    case
        when current_inventory.stock_quantity <= 0 then 'out_of_stock'
        when current_inventory.stock_quantity < 10 then 'critical'
        when current_inventory.stock_quantity < 20 then 'low'
        else 'ok'
    end                                               as stock_status
from current_inventory
left join books on current_inventory.book_id = books.book_id
where current_inventory.stock_quantity < 20
   or current_inventory.stock_quantity is null
