with source as (
    select * from {{ ref('bronze_orders') }}
),

cleaned as (
    select
        order_id,
        customer_id,
        order_date,
        lower(trim(status))                        as status,
        order_total,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
