/*
Um modelo para pivotar os métodos de pagamento, transformando as linhas em colunas.
Ele seleciona os métodos de pagamento distintos da tabela de pagamentos
e depois usa esses métodos para criar colunas dinâmicas na consulta SQL.
Cada coluna representa o valor total pago para aquele método de pagamento específico, agrupado por order_id.
Tudo isso utilizando o jinja para gerar a consulta SQL dinamicamente com base nos métodos de pagamento encontrados na tabela de pagamentos.
*/

{%- set sql -%}
    select distinct payment_method
    from {{ ref('stg_stripe__payment') }}
    where payment_status = 'success'
{%- endset -%}

{%- set results = run_query(sql) -%}
{%- set payment_methods = [] -%}

{%- if execute -%}
  {%- for row in results -%}
    {% set _ = payment_methods.append(row.payment_method) %}
  {%- endfor -%}
{%- endif -%}


with payments as (
    select * from {{ref('stg_stripe__payment')}}
    where payment_status = 'success'
),
pivoted as (
    select
        order_id,
        {% for method in payment_methods %}
            sum(case when payment_method = "{{ method }}" then payment_amount else 0 end) as {{ method }}_amount
            {%- if not loop.last -%},{%- endif -%}
        {% endfor %}    
    from payments
    group by order_id
)
select * from pivoted