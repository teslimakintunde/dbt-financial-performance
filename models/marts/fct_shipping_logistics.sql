{{ config(materialized='table') }}

with sales as (
    select * from {{ ref('stg_sales') }}
)

select
    order_id,
    customer_id,
    product_id,
    region,
    sales_channel,
    order_date,
    estimated_delivery,
    actual_delivery,
    
    -- 1. Calculate variance in days between actual and estimated delivery
    date_diff(actual_delivery, estimated_delivery, DAY) as delivery_variance_days,
    
    -- 2. Flag rows where actual delivery exceeded the estimate
    case 
        when actual_delivery > estimated_delivery then "1" 
        else "0" 
    end as is_late_shipment

from sales
-- Filter out rows where delivery records are incomplete to ensure valid analytics
where actual_delivery is not null 
  and estimated_delivery is not null