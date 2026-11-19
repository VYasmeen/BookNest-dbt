with orders as (
    select * from {{ ref('fct_orders') }}
),
payments as (
    select * from {{ ref('fct_payments') }}
),

order_summary as (
    select
        order_id,
        customer_id,
        order_date,
        status,
        stated_order_total,
        computed_order_total,
        total_mismatch,
        has_orphan_customer_id
    from orders
),

payment_summary as (
    select
        order_id,
        payment_id,
        payment_method,
        payment_status_clean,
        payment_amount,
        payment_mismatch,
        has_reconciliation_issue,
        days_to_payment
    from payments
)

select
    order_summary.order_id,
    order_summary.customer_id,
    order_summary.order_date,
    order_summary.status                               as order_status,
    order_summary.stated_order_total,
    order_summary.computed_order_total,
    order_summary.total_mismatch                       as order_mismatch,
    payment_summary.payment_id,
    payment_summary.payment_method,
    payment_summary.payment_status_clean,
    payment_summary.payment_amount,
    payment_summary.payment_mismatch,
    case
        when order_summary.total_mismatch > 0.01 then true
        when payment_summary.has_reconciliation_issue then true
        else false
    end                                                as needs_investigation,
    payment_summary.days_to_payment,
    order_summary.has_orphan_customer_id
from order_summary
left join payment_summary on order_summary.order_id = payment_summary.order_id
order by order_summary.order_date desc
