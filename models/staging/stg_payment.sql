select
 id as payment_id,
 orderid as order_id,
 paymentmethod as payment_method,
 status,

 -- amount is stored in cents, convert to dollars
-- calulado sem utilizar a macro
amount * 1.0/100 as payment_amount_without_macro,
-- utilizando a macro
 {{ cents_to_dollars("amount") }} as payment_amount_with_macro,
created as created_at

from {{ source('stripe', 'payment') }}