{{ config(materialized='view') }}

with source_customers as (
    select * from {{ source('raw_sales_data', 'customers') }}
)

select
    -- Trim identifier and profile text strings
    trim(cast(customer_id as string)) as customer_id,
    trim(full_name) as full_name,
    trim(email) as email,
    trim(cast(phone_number as string)) as phone_number,
    trim(city) as city,
    trim(region) as customer_region,
    cast(age as int64) as customer_age,
    trim(customer_segment) as customer_segment,
    trim(acquisition_channel) as acquisition_channel,
    trim(acquisition_campaign_id) as acquisition_campaign_id,
    
    -- Cleaned Gender Logic
    case
        when lower(trim(gender)) in ('female', 'femal', 'femle', 'f') then 'Female'
        when lower(trim(gender)) in ('male', 'm') then 'Male'
        else trim(gender)
    end as gender,

    -- Cleaned Loyalty Tier Logic
    case
        when lower(trim(loyalty_tier)) in ('silver', 'silvr') then 'Silver'
        when lower(trim(loyalty_tier)) in ('gold', 'gld') then 'Gold'
        when lower(trim(loyalty_tier)) in ('platinum', 'platnum') then 'Platinum'
        when lower(trim(loyalty_tier)) in ('bronze', 'brnze') then 'Bronze'
        else trim(loyalty_tier)
    end as loyalty_tier,

    -- Cleaned Preferred Payment Logic
    case
        when lower(trim(preferred_payment)) in ('creditcard', 'credit card') then 'Credit Card'
        when lower(trim(preferred_payment)) in ('paypal', 'pay pal') then 'PayPal'
        when lower(trim(preferred_payment)) in ('banktransfer', 'bank transfer') then 'Bank Transfer'
        when lower(trim(preferred_payment)) in ('debit card', 'debitcard') then 'Debit Card'
        when lower(trim(preferred_payment)) = 'cash' then 'Cash'
        else trim(preferred_payment)
    end as preferred_payment,

    -- Dynamic Date Conversion for Signup Date
    coalesce(
        safe.parse_date('%Y-%m-%d', trim(signup_date)),
        safe.parse_date('%d-%b-%Y', trim(signup_date)),
        safe.parse_date('%d-%b-%y', trim(signup_date)),
        safe.parse_date('%d-%m-%y', trim(signup_date)),
        safe.parse_date('%d/%m/%Y', trim(signup_date)),
        safe.parse_date('%m/%d/%Y', trim(signup_date))
    ) as signup_date

from source_customers
