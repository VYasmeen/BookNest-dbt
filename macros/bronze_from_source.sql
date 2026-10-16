{#
    Collapses the Bronze "1:1 from source + metadata" pattern.
    Every Bronze model is the same shape: pass through all columns from a
    declared source, tag with ingestion timestamp and source name.
#}

{% macro bronze_from_source(table_name, source_name='booknest_raw') %}

select
    *,
    current_timestamp                                 as _ingested_at,
    '{{ source_name }}.{{ table_name }}'              as _source_name
from {{ source(source_name, table_name) }}

{% endmacro %}
