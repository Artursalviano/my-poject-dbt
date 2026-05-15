Projeto dbt — Analytics Engineering

Visão geral
- Repositório dbt para transformação de dados (modelos em `models/`).
- Tudo está orquestrado no Databricks: as execuções são agendadas e disparadas via Databricks Jobs.

Orquestração (Databricks)
- Este projeto é executado em produção através de um Job no Databricks. O Job inicia o cluster/configuração necessária e executa os comandos dbt no ambiente Databricks.
- Substitua `JOB_ID` e o nome do cluster no Databricks pelas configurações do seu workspace.

Fluxo de execução
1. O Job do Databricks provisiona ou reutiliza o cluster configurado.
2. O Job executa os comandos dbt necessários (ex.: `dbt compile`, `dbt run`, `dbt test`).
3. Artefatos compilados e resultados ficam em `target/` e podem ser armazenados/consumidos pelo pipeline de observabilidade.

Executando localmente (desenvolvimento)
- Instale o dbt e o adapter apropriado para Databricks localmente se precisar desenvolver sem o Databricks Job.
- Comandos úteis:

```
# compilar modelos
dbt compile

# rodar modelos
dbt run

# rodar testes
dbt test
```

Boas práticas
- Não versionar `profiles.yml` nem credenciais — use o secrets management do Databricks ou variáveis do Job.
- Testes e validações devem ser executados tanto localmente quanto via Job para garantir consistência.

Recursos
- Documentação dbt: https://docs.getdbt.com/docs/introduction

Contato
- Para dúvidas sobre orquestração no Databricks, contate o time responsável pelo workspace Databricks.

Macro de geração de `schema`
- Este projeto inclui uma macro customizada que gera nomes de `schema` com base na pasta em que o modelo está localizado. A macro sobrescreve a macro padrão `generate_schema_name` do dbt e recebe informações do `node` do modelo para derivar o nome do schema.
- Comportamento geral:
	- Extrai a pasta relativa do arquivo do modelo dentro de `models/` (ex.: `models/marts/dim_customers.sql` → pasta `marts`).
	- Normaliza o nome (minúsculas, caracteres válidos) e retorna o nome do `schema` resultante.
	- Pode prefixar ou sufixar com o ambiente (ex.: `dev_`, `prd_`) conforme configuração da macro.
- Exemplos:
	- `models/marts/dim_customers.sql` 
        - schema gerado: `marts`
        - dataset gerado: `analytics.marts.dim_customers` 
	- `models/staging/jaffle_shop/stg_customers.sql` 
        - schema gerado: `staging` 
        - dataset gerado `analytics.staging.stg_customers`
- Onde está aplicada:
	- A macro é usada globalmente pelo dbt ao gerar o `schema` para cada modelo, sem necessidade de configurar `schema` model-a-modelo.

Código da macro `generate_schema_name`

```jinja2
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
```

**Explicação linha por linha:**

1. **`{% macro generate_schema_name(custom_schema_name, node) -%}`**
   - Define a macro que será chamada automaticamente pelo dbt para cada modelo
   - Recebe dois parâmetros: `custom_schema_name` (configuração opcional do modelo) e `node` (metadados do modelo)

2. **`{%- set default_schema = target.schema -%}`**
   - Captura o schema padrão configurado no `profiles.yml` via `target.schema`
   - Será usado como fallback se a lógica não encontrar uma pasta específica

3. **`node.fqn | length > 2`**
   - `fqn` (Fully Qualified Name) é uma lista de nomes do caminho do modelo
   - Exemplo: `['analytics_engineering_dbt', 'marts', 'dim_customers']`
   - Verifica se tem mais de 2 elementos (projeto + pelo menos 1 pasta + modelo)

4. **`{{ node.fqn[1] | trim }}`**
   - Extrai a primeira pasta do caminho (índice 1 da lista)
   - Exemplo: de `['analytics_engineering_dbt', 'marts', 'dim_customers']` pega `marts`
   - `| trim` remove espaços em branco antes e depois

5. **`{{ default_schema }}`**
   - Se não houver pasta específica, retorna o schema padrão do `profiles.yml`
   - Serve como fallback para modelos na raiz de `models/`

Integrações e fluxo de código
- Repositório Git: código fonte e alterações são versionados em Git; os branches acionam pipelines/Jobs conforme convenção do time.
- Databricks: os Jobs do Databricks estão configurados para puxar o código do Git (ou integrar via CI) e executar os comandos dbt no cluster.
- dbt Cloud (quando aplicável): pode ser usado para orquestração/monitoramento adicional ou como alternativa à execução direta no Databricks; integra-se ao Git e ao Databricks quando configurado.
- VS Code: ambiente de desenvolvimento local — edite modelos e macros, use a extensão do dbt e controle de versão Git local; mudanças são commitadas e pushadas para o repositório que aciona os Jobs/CI.
- Credenciais e segredos: mantenha fora do repositório; use o secrets manager do Databricks, variáveis do Job ou o gerenciador de segredos do seu CI/CD.


