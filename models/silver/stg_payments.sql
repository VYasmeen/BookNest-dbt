with source as (
    select * from {{ ref('bronze_payments') }}
),

cleaned as (
    select
        payment_id,
        order_id,
        lower(trim(payment_method))                as payment_method,
        lower(trim(payment_status))                as payment_status,
        amount,
        paid_at,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
