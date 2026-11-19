with payments as (
    select * from {{ ref('stg_payments') }}
),
orders as (
    select * from {{ ref('stg_orders') }}
),
customers as (
    select * from {{ ref('dim_customers') }}
)

select
    payments.payment_id,
    payments.order_id,
    orders.customer_id,
    customers.full_name,
    orders.order_date,
    payments.paid_at,
    payments.payment_method,
    payments.payment_status,
    orders.status                                      as order_status,
    orders.order_total                                 as stated_order_total,
    payments.amount                                    as payment_amount,
    abs(coalesce(payments.amount, 0)
      - coalesce(orders.order_total, 0))               as payment_mismatch,
    case
        when abs(coalesce(payments.amount, 0)
              - coalesce(orders.order_total, 0)) > 0.01 then true
        else false
    end                                                as has_reconciliation_issue,
    case
        when payments.paid_at is not null
         and orders.order_date is not null
        then datediff('day', orders.order_date, payments.paid_at)
        else null
    end                                                as days_to_payment,
    case
        when payments.payment_status = 'completed' then 'paid'
        when payments.payment_status = 'pending' then 'pending'
        when payments.payment_status = 'failed' then 'failed'
        else 'unknown'
    end                                                as payment_status_clean
from payments
left join orders    on payments.order_id = orders.order_id
left join customers on orders.customer_id = customers.customer_id
