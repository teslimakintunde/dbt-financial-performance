{{ config(materialized='view') }}

with source_products as (
    select * from {{ source('raw_sales_data', 'products') }}
)

select
    cast(product_id as string) as product_id,
    product_name,
    category as product_category,
    cast(base_price as numeric) as base_price,
    cast(unit_cost as numeric) as unit_cost,
    supplier_code,
    country_of_origin,
    
    is_active,

    -- Parse launch dates after converting 'Sept' to standard abbreviated 'Sep' form
    coalesce(
        safe.parse_date('%Y-%m-%d', replace(launch_date, 'Sept', 'Sep')),
        safe.parse_date('%d-%b-%Y', replace(launch_date, 'Sept', 'Sep')),
        safe.parse_date('%d-%b-%y', replace(launch_date, 'Sept', 'Sep')),
        safe.parse_date('%d-%m-%y', replace(launch_date, 'Sept', 'Sep')),
        safe.parse_date('%d/%m/%Y', replace(launch_date, 'Sept', 'Sep')),
        safe.parse_date('%m/%d/%Y', replace(launch_date, 'Sept', 'Sep'))
    ) as launch_date

from source_products
