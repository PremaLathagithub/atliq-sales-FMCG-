show databases;

use retail_events_db;

show tables;

select * from dim_campaigns;
select * from dim_products;
select * from dim_stores;
select * from fact_events;

-- product name and base_price >500 and promtype 'BOGOF'

select product_name,base_price,promo_type from dim_products 
inner join fact_events
 on dim_products.product_code=fact_events.product_code
where base_price>500 
and promo_type="BOGOF";

-- no of city and store count using orderby and groupby

select count(store_id) as Store_num,
 city from dim_stores
where store_id in (select distinct store_id from fact_events)
group by city
order by store_num desc;

-- before and after promotion




use retail_events_db;


ALTER TABLE fact_events
CHANGE COLUMN `quantity_sold(before_promo)` quantity_sold_before_promo INT;
ALTER TABLE fact_events
CHANGE COLUMN `quantity_sold(after_promo)` quantity_sold_after_promo INT;

select  campaign_name, sum(base_price*quantity_sold_before_promo)/1000000 as total_revenue_before_promotion ,
sum(base_price*quantity_sold_after_promo)/1000000 as total_revenue_after_promotion 
from dim_campaigns,fact_events 
group by campaign_name;

-- with cte table

WITH PromoPrices AS (
    SELECT
        fe.*,
        CASE
            WHEN fe.promo_type = '50% OFF' THEN fe.base_price * 0.5
            WHEN fe.promo_type = '33% OFF' THEN fe.base_price * 0.67
            WHEN fe.promo_type = '25% OFF' THEN fe.base_price * 0.75
            WHEN fe.promo_type = '500 Cashback' THEN fe.base_price - 500
            WHEN fe.promo_type = 'BOGOF' THEN fe.base_price / 2
            ELSE fe.base_price  
        END AS promo_price
    FROM
        fact_events fe
)
SELECT
    dc.campaign_name,
    ROUND(SUM(f.quantity_sold_before_promo * f.base_price) / 1000000, 2) AS total_revenue_before_promotion,
    ROUND(SUM(f.quantity_sold_after_promo * p.promo_price) / 1000000, 2) AS total_revenue_after_promotion
FROM
    dim_campaigns dc
JOIN
    fact_events f ON dc.campaign_id = f.campaign_id
JOIN
    PromoPrices p ON p.event_id = f.event_id
GROUP BY
    dc.campaign_name;









-- top category ISU during diwali campaign

select p.category,
 (( sum(f.quantity_sold_after_promo)-sum(f.quantity_sold_before_promo))/sum(f.quantity_sold_before_promo)*100) as ISU_percentage,
rank()
over(
order by((sum( f.quantity_sold_after_promo)-sum(f.quantity_sold_before_promo))/sum(f.quantity_sold_before_promo)*100)
 desc)
as rank_order
from dim_products p
join 
fact_events f on p.product_code=f.product_code
where campaign_id='CAMP_DIW_01'
group by 
p.category
order by
ISU_percentage desc;

-- top 5 product ranked by revenue percentage(IR) across all campaign

WITH PromoPrices AS (
    SELECT
        fe.*,
        CASE
            WHEN fe.promo_type = '50% OFF' THEN fe.base_price * 0.5
            WHEN fe.promo_type = '33% OFF' THEN fe.base_price * 0.67
            WHEN fe.promo_type = '25% OFF' THEN fe.base_price * 0.75
            WHEN fe.promo_type = '500 Cashback' THEN fe.base_price - 500
            WHEN fe.promo_type = 'BOGOF' THEN fe.base_price / 2
            ELSE fe.base_price  -- Default to base price if promo_type doesn't match any condition
        END AS promo_price
    FROM
        fact_events fe
)
SELECT
    dp.product_name, dp.category,
    ((sum(f.quantity_sold_after_promo* p.promo_price) - sum(f.quantity_sold_before_promo*f.base_price))/sum(f.quantity_sold_before_promo*f.base_price)*100) AS IR_PERc
    
FROM
    dim_products dp
JOIN
    fact_events f ON dp.product_code = f.product_code
JOIN
    PromoPrices p ON p.event_id = f.event_id
GROUP BY
 dp.product_name,
    dP.category
    order by IR_PERc DESC
    limit 5;