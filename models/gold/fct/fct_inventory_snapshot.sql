with inv as (
    select * from {{ ref('snap_inventory') }}
),
books as (
    select * from {{ ref('dim_books') }}
)

select
    inv.book_id,
    books.title,
    books.genre,
    books.price,
    inv.stock_quantity,
    inv.last_restocked_at,
    cast(inv.dbt_valid_from as date)                  as snapshot_date,
    cast(inv.dbt_valid_to   as date)                  as snapshot_valid_until,
    case when inv.dbt_valid_to is null
         then true else false end                     as is_current
from inv
left join books on inv.book_id = books.book_id
