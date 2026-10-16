with books as (
    select * from {{ ref('stg_books') }}
)

select
    book_id,
    title,
    author,
    genre,
    price,
    published_year,
    case
        when price is null then 'unknown'
        when price < 10   then 'budget'
        when price < 20   then 'standard'
        when price < 30   then 'premium'
        else 'luxury'
    end                                            as price_band,
    has_invalid_price
from books
