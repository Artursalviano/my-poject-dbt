select
        id as customer_id,
        first_name,
        last_name

    from {{ source('artur_shop', 'customers') }}
