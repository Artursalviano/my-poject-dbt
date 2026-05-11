{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    
    {# 
       A lógica abaixo verifica se o modelo está dentro de uma subpasta em 'models'.
       node.fqn é uma lista: [projeto, pasta, subpasta, modelo]
       O fqn[1] geralmente é a primeira pasta logo após a pasta 'models'
    #}

    {%- if node.fqn | length > 2 -%}
        
        {# Pega o nome da pasta (ex: marts ou staging) #}
        {{ node.fqn[1] | trim }}

    {%- else -%}

        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}