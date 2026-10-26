{{ config(materialized='table') }}

with sales as (
    select * from {{ ref('stg_sales') }}
),

customers as (
    select * from {{ ref('stg_customers') }}
),

-- Step 1: Aggregate total spent (Net Revenue) at the individual customer level
customer_lifetime_value as (
    select
        customer_id,
        count(distinct order_id) as total_lifetime_orders,
        -- Total amount the customer actually paid across all orders
        sum((quantity * unit_price) * (1 - discount_applied)) as customer_lifetime_value_net
    from sales
    group by 1
),

-- Step 2: Join customer LTV metrics back to their original acquisition campaigns
campaign_joined as (
    select
        clv.customer_id,
        clv.total_lifetime_orders,
        clv.customer_lifetime_value_net,
        -- Group missing/null tracking data into clean fallback categories
        coalesce(c.acquisition_campaign_id, 'No Campaign / Organic') as acquisition_campaign_id,
        coalesce(c.acquisition_channel, 'Direct / Unknown') as acquisition_channel
    from customer_lifetime_value clv
    left join customers c
        on clv.customer_id = c.customer_id
)

-- Step 3: Aggregate metrics by campaign and channel to evaluate ROI performance
select
    acquisition_campaign_id,
    acquisition_channel,
    
    -- Volume performance metrics
    count(distinct customer_id) as total_customers_acquired,
    sum(total_lifetime_orders) as total_orders_generated,
    
    -- Financial return metrics
    round(cast(sum(customer_lifetime_value_net) as numeric), 2) as total_campaign_revenue,
    
    -- Average Customer Lifetime Value (LTV) for this campaign
    round(
        cast(
            safe_divide(sum(customer_lifetime_value_net), count(distinct customer_id)) 
        as numeric), 
        2
    ) as average_customer_ltv,

    -- Average orders per customer (identifies repeat-purchasing behavior)
    round(
        cast(
            safe_divide(sum(total_lifetime_orders), count(distinct customer_id)) 
        as numeric), 
        2
    ) as average_orders_per_customer

from campaign_joined
group by 1, 2
order by total_campaign_revenue desc
