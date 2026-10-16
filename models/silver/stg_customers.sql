with source as (
    select * from {{ ref('bronze_customers') }}
),

cleaned as (
    select
        customer_id,
        trim(first_name)                           as first_name,
        trim(last_name)                            as last_name,
        lower(trim(email))                         as email,
        signup_date,
        nullif(trim(country), '')                  as country,
        nullif(trim(city), '')                     as city,
        case when signup_date > current_date
             then true else false end              as has_future_signup_date,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
