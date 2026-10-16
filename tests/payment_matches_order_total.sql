{{
    config(
        severity='warn',
        error_if='>0'
    )
}}

-- Business rule: a payment's amount should equal the order's stated total.
-- Design §3.6 calls out "amount != order_total" as a known source DQ issue,
-- so this test exists to count and surface violations without failing the build.

with payments as (
    select * from {{ ref('stg_payments') }}
),
orders as (
    select * from {{ ref('stg_orders') }}
)

select
    payments.payment_id,
    payments.order_id,
    payments.amount                                   as payment_amount,
    orders.order_total                                as stated_order_total,
    abs(payments.amount - orders.order_total)         as mismatch
from payments
join orders using (order_id)
where abs(payments.amount - orders.order_total) > 0.01
