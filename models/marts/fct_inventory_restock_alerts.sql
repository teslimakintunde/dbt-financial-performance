{{ config(materialized='table') }}

with sales as (
    select * from {{ ref('stg_sales') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

-- Step 1: Calculate historical sales velocity (total units sold) to rank priority
product_velocity as (
    select
        product_id,
        sum(quantity) as total_units_sold,
        count(distinct order_id) as total_orders_placed
    from sales
    group by 1
)

-- Step 2: Combine metrics, filter for risk factors, and build the alert list
select
    p.product_id,
    p.product_name,
    p.product_category,
    p.supplier_code,
    p.current_stock_level,
    p.reorder_level,
    
    -- Calculate how short we are on stock
    (p.reorder_level - p.current_stock_level) as stock_deficit,
    
    -- Bring in velocity metrics to help operations prioritize
    coalesce(v.total_units_sold, 0) as historical_units_sold,
    
    -- Assign a clear priority tier based on sales velocity
    case 
        when v.total_units_sold >= 100 then '1 - Critical (High Velocity)'
        when v.total_units_sold >= 30 then '2 - Medium Priority'
        else '3 - Low Priority (Slow Mover)'
    end as restocking_priority

from products p
left join product_velocity v
    on p.product_id = v.product_id

where p.is_active 
  and p.current_stock_level < p.reorder_level
order by historical_units_sold desc, stock_deficit desc
