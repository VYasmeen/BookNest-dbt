{{
    config(
        materialized='incremental',
        unique_key='order_id'
    )
}}

with source as (
    select * from {{ source('booknest_raw', 'raw_orders') }}

    {% if is_incremental() %}
    where order_date > (select coalesce(max(order_date), '1900-01-01'::date) from {{ this }})
    {% endif %}
)

select
    *,
    current_timestamp                                 as _ingested_at,
    'booknest_raw.raw_orders'                         as _source_name
from source
