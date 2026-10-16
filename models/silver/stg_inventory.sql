with source as (
    select * from {{ ref('bronze_inventory') }}
),

cleaned as (
    select
        book_id,
        stock_quantity,
        last_restocked_at,
        case when stock_quantity < 0 then true else false end as has_negative_stock,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
