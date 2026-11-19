with customer_sales as (
    select
        customers.customer_id,
        customers.full_name,
        customers.email,
        customers.signup_date,
        current_date                                   as analysis_date,
        count(distinct orders.order_id)                as order_count,
        min(orders.order_date)                         as first_order_date,
        max(orders.order_date)                         as last_order_date,
        (current_date - max(orders.order_date))        as days_since_last_order,
        round(
            cast(current_date - min(orders.order_date) as float) /
            nullif(count(distinct orders.order_id) - 1, 0),
            2
        )                                              as avg_days_between_orders,
        sum(items.line_total)                          as lifetime_value
    from {{ ref('dim_customers') }} customers
    left join {{ ref('fct_order_items') }} items on customers.customer_id = items.customer_id and items.is_valid_sale
    left join {{ ref('stg_orders') }} orders on items.order_id = orders.order_id
    group by customers.customer_id, customers.full_name, customers.email, customers.signup_date
),
rfm_calculations as (
    select
        *,
        percent_rank() over (order by days_since_last_order desc) as recency_percentile,
        percent_rank() over (order by order_count) as frequency_percentile,
        percent_rank() over (order by lifetime_value) as monetary_percentile
    from customer_sales
),
rfm_segments as (
    select
        customer_id,
        full_name,
        email,
        signup_date,
        analysis_date,
        order_count,
        first_order_date,
        last_order_date,
        days_since_last_order,
        avg_days_between_orders,
        round(coalesce(lifetime_value, 0), 2)         as lifetime_value,
        case
            when order_count = 0 then 'never_purchased'
            when recency_percentile < 0.25 and frequency_percentile > 0.75 and monetary_percentile > 0.75 then 'champions'
            when recency_percentile < 0.25 and frequency_percentile > 0.5 and monetary_percentile > 0.5 then 'loyal_customers'
            when recency_percentile < 0.5 and frequency_percentile > 0.5 then 'at_risk'
            when recency_percentile > 0.75 and frequency_percentile > 0.75 then 'cant_lose_them'
            when recency_percentile > 0.75 then 'lost_customers'
            when frequency_percentile < 0.25 then 'one_time_buyers'
            else 'regular_customers'
        end                                            as customer_segment
    from rfm_calculations
)

select * from rfm_segments
