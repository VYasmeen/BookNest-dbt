with source as (
    select * from {{ ref('bronze_order_items') }}
),

cleaned as (
    select
        order_item_id,
        order_id,
        book_id,
        quantity,
        unit_price,
        case when quantity <= 0 then true else false end  as has_invalid_quantity,
        case when unit_price = 0 then true else false end as has_zero_price,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
