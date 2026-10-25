{{ config(materialized='view') }}

with source_sales as (
    select * from {{ source('raw_sales_data', 'sales') }}
)

select
    cast(order_id as string) as order_id,
    cast(customer_id as string) as customer_id,
    cast(product_id as string) as product_id,
    cast(quantity as int64) as quantity,
    cast(unit_price as numeric) as unit_price,
    cast(unit_cost as numeric) as unit_cost,
    cast(discount_applied as numeric) as discount_applied,
    cast(shipping_cost as numeric) as shipping_cost,
    region,
    sales_channel,
    
    -- Cleaned Delivery Status
    case 
        when lower(trim(delivery_status)) in ('deliverd', 'delivered') then 'Delivered'
        when lower(trim(delivery_status)) in ('delayyed', 'delayed') then 'Delayed'
        when lower(trim(delivery_status)) in ('cancelled', 'canceled') then 'Cancelled'
        when lower(trim(delivery_status)) = 'pending' then 'Pending'
        when lower(trim(delivery_status)) = 'processing' then 'Processing'
        else trim(delivery_status)
    end as delivery_status,

    -- Cleaned Payment Method
    case
        when lower(trim(payment_method)) in ('paypal', 'pay pal') then 'PayPal'
        when lower(trim(payment_method)) in ('credit card', 'creditcard') then 'Credit Card'
        when lower(trim(payment_method)) in ('bank transfer', 'banktransfer') then 'Bank Transfer'
        when lower(trim(payment_method)) in ('debit card', 'debitcard') then 'Debit Card'
        when lower(trim(payment_method)) = 'cash' then 'Cash'
        else trim(payment_method)
    end as payment_method,

    return_requested,

    -- Cleaned Dates using BigQuery SAFE.PARSE_DATE
    coalesce(
        safe.parse_date('%Y-%m-%d', order_date),
        safe.parse_date('%d-%b-%Y', order_date),
        safe.parse_date('%d-%b-%y', order_date),
        safe.parse_date('%d-%m-%y', order_date),
        safe.parse_date('%d/%m/%Y', order_date),
        safe.parse_date('%m/%d/%Y', order_date)
    ) as order_date,

    coalesce(
        safe.parse_date('%Y-%m-%d', estimated_delivery),
        safe.parse_date('%d-%b-%Y', estimated_delivery),
        safe.parse_date('%d-%b-%y', estimated_delivery),
        safe.parse_date('%d-%m-%y', estimated_delivery),
        safe.parse_date('%d/%m/%Y', estimated_delivery),
        safe.parse_date('%m/%d/%Y', estimated_delivery)
    ) as estimated_delivery,

    coalesce(
        safe.parse_date('%Y-%m-%d', actual_delivery),
        safe.parse_date('%d-%b-%Y', actual_delivery),
        safe.parse_date('%d-%b-%y', actual_delivery),
        safe.parse_date('%d-%m-%y', actual_delivery),
        safe.parse_date('%d/%m/%Y', actual_delivery),
        safe.parse_date('%m/%d/%Y', actual_delivery)
    ) as actual_delivery

from source_sales
