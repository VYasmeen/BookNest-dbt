with customers as (
    select * from {{ ref('stg_customers') }}
)

select
    customer_id,
    first_name,
    last_name,
    first_name || ' ' || last_name                 as full_name,
    email,
    signup_date,
    country,
    city,
    datediff('day', signup_date, current_date)     as days_since_signup,
    has_future_signup_date
from customers
