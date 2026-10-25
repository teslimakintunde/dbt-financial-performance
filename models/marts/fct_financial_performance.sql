{{ config(materialized='table') }}

with sales as (
    select * from {{ ref('stg_sales') }}
),

products as (
    select * from {{ ref('stg_products') }}
)

select
    s.order_id,
    s.customer_id,
    s.product_id,
    p.product_name,
    p.product_category,
    s.quantity,
    
    -- 1. Gross Revenue Calculation
    (s.quantity * s.unit_price) as gross_revenue,
    
    -- 2. Value reduction via Discounts
    ((s.quantity * s.unit_price) * s.discount_applied) as total_discount_amount,
    
    -- 3. Net Revenue (What the customer actually paid)
    ((s.quantity * s.unit_price) * (1 - s.discount_applied)) as net_revenue,
    
    -- 4. Cost of Goods Sold (COGS)
    (s.quantity * s.unit_cost) as cost_of_goods_sold,
    
    s.shipping_cost,
    
    -- 5. Net Profit Formula: Net Revenue - COGS - Shipping Cost
    (((s.quantity * s.unit_price) * (1 - s.discount_applied)) - (s.quantity * s.unit_cost) - s.shipping_cost) as net_profit,
    
    -- 6. Profit Margin Percentage
    safe_divide(
        (((s.quantity * s.unit_price) * (1 - s.discount_applied)) - (s.quantity * s.unit_cost) - s.shipping_cost),
        ((s.quantity * s.unit_price) * (1 - s.discount_applied))
    ) * 100 as profit_margin_percentage

from sales s
left join products p 
    on s.product_id = p.product_id