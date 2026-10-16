with orders as (
    select * from {{ ref('stg_orders') }}
),
items as (
    select * from {{ ref('stg_order_items') }}
),
customers as (
    select * from {{ ref('stg_customers') }}
),

items_agg as (
    select
        order_id,
        count(*)                                      as item_count,
        sum(quantity)                                 as total_quantity,
        sum(quantity * unit_price)                    as computed_order_total
    from items
    where not has_invalid_quantity and not has_zero_price
    group by order_id
)

select
    orders.order_id,
    orders.customer_id,
    orders.order_date,
    orders.status,
    orders.order_total                                as stated_order_total,
    items_agg.computed_order_total,
    items_agg.item_count,
    items_agg.total_quantity,
    abs(
        coalesce(orders.order_total, 0)
      - coalesce(items_agg.computed_order_total, 0)
    )                                                 as total_mismatch,
    case when customers.customer_id is null
         then true else false end                     as has_orphan_customer_id
from orders
left join items_agg on orders.order_id    = items_agg.order_id
left join customers on orders.customer_id = customers.customer_id
