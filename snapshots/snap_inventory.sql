{% snapshot snap_inventory %}

{{
    config(
      target_schema='snapshots',
      unique_key='book_id',
      strategy='check',
      check_cols=['stock_quantity', 'last_restocked_at'],
      invalidate_hard_deletes=False
    )
}}

select
    book_id,
    stock_quantity,
    last_restocked_at
from {{ ref('stg_inventory') }}

{% endsnapshot %}
