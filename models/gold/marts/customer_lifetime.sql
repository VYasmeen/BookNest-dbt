with customers as (
    select * from {{ ref('dim_customers') }}
),
orders as (
    select * from {{ ref('fct_orders') }}
),
items as (
    select * from {{ ref('fct_order_items') }}
    where is_valid_sale
),

per_customer_items as (
    select
        orders.customer_id,
        sum(items.line_total)                        as lifetime_revenue,
        sum(items.quantity)                          as lifetime_units
    from items
    join orders on items.order_id = orders.order_id
    group by orders.customer_id
),

per_customer_orders as (
    select
        customer_id,
        count(*)                                      as order_count,
        min(order_date)                               as first_order_date,
        max(order_date)                               as last_order_date
    from orders
    where status not in ('cancelled','returned')
    group by customer_id
)

select
    customers.customer_id,
    customers.full_name,
    customers.email,
    customers.country,
    coalesce(per_customer_orders.order_count, 0)      as order_count,
    coalesce(per_customer_items.lifetime_revenue, 0)  as lifetime_revenue,
    coalesce(per_customer_items.lifetime_units, 0)    as lifetime_units,
    case
        when coalesce(per_customer_orders.order_count, 0) = 0 then 0
        else per_customer_items.lifetime_revenue
             / per_customer_orders.order_count
    end                                               as avg_order_value,
    per_customer_orders.first_order_date,
    per_customer_orders.last_order_date,
    datediff(
        'day',
        per_customer_orders.first_order_date,
        per_customer_orders.last_order_date
    )                                                 as days_active
from customers
left join per_customer_orders
       on customers.customer_id = per_customer_orders.customer_id
left join per_customer_items
       on customers.customer_id = per_customer_items.customer_id
