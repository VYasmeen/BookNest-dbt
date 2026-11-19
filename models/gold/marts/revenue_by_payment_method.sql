with payments as (
    select * from {{ ref('fct_payments') }}
),
order_items as (
    select * from {{ ref('fct_order_items') }}
)

select
    payments.payment_method,
    payments.payment_status_clean,
    payments.order_date,
    count(distinct payments.order_id)                  as order_count,
    count(distinct payments.payment_id)                as payment_count,
    sum(order_items.quantity)                          as units_sold,
    sum(payments.payment_amount)                       as total_payment_amount,
    sum(case when order_items.is_valid_sale
             then order_items.line_total else 0 end)  as revenue_recognized,
    avg(payments.days_to_payment)                      as avg_days_to_payment
from payments
left join order_items on payments.order_id = order_items.order_id
where payments.payment_status_clean != 'unknown'
group by
    payments.payment_method,
    payments.payment_status_clean,
    payments.order_date
order by
    payments.order_date desc,
    payments.payment_method
