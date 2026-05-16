select
customer_id,
order_date,
{{ dbt_utils.generate_surrogate_key(['customer_id', 'order_date']) }} as pk,
count(*) as total_orders

from {{ref('stg_jaffle_shop__orders')}}

group by all