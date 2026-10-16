with source as (
    select * from {{ ref('bronze_books') }}
),

cleaned as (
    select
        book_id,
        trim(title)                                as title,
        trim(author)                               as author,
        case
            when lower(trim(genre)) = 'sci-fi' then 'Science Fiction'
            else trim(genre)
        end                                        as genre,
        case when price < 0 then null else price end as price,
        case when price < 0 then true else false end as has_invalid_price,
        published_year,
        _ingested_at,
        _source_name
    from source
)

select * from cleaned
