{{ config(materialized='table') }}

with sales as (
    select * from {{ ref('stg_sales') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

-- Step 1: Calculate metrics at the Order level to establish unique order values
order_metrics as (
    select
        s.order_id,
        s.customer_id,
        -- Gross Revenue before discounts
        sum(s.quantity * s.unit_price) as gross_order_value,
        -- Net Revenue (what the customer actually paid)
        sum((s.quantity * s.unit_price) * (1 - s.discount_applied)) as net_order_value,
        -- Average discount applied to this order
        avg(s.discount_applied) as avg_order_discount_rate
    from sales s
    group by 1, 2
),

-- Step 2: Join orders with customer profiles to link loyalty tiers
customer_order_joined as (
    select
        om.order_id,
        om.customer_id,
        om.gross_order_value,
        om.net_order_value,
        om.avg_order_discount_rate,
        coalesce(c.loyalty_tier, 'Non-Member') as loyalty_tier,
        c.customer_segment
    from order_metrics om
    left join customers c
        on om.customer_id = c.customer_id
)

-- Step 3: Final aggregation by loyalty tier to answer the business question
select
    loyalty_tier,
    count(distinct customer_id) as total_unique_customers,
    count(distinct order_id) as total_orders,
    
    -- Financial impact metrics
    round(cast(sum(net_order_value) as numeric), 2) as total_net_revenue,
    
    -- AOV based on what they actually spent (Net Revenue)
    round(cast(safe_divide(sum(net_order_value), count(distinct order_id)) as numeric), 2) as average_order_value_net,
    
    -- AOV based on stick price before coupons (Gross Revenue)
    round(cast(safe_divide(sum(gross_order_value), count(distinct order_id)) as numeric), 2) as average_order_value_gross,
    
    -- Overall discount percentage behavior for this tier
    round(cast(avg(avg_order_discount_rate) * 100 as numeric), 2) as average_discount_percentage_applied

from customer_order_joined
group by 1
order by average_order_value_net desc
