--================================================================================
--DDL: Create view & Schema
--================================================================================
DROP VIEW IF EXISTS vw_products;

CREATE VIEW vw_products AS
SELECT 
    p.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g
FROM products p
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name;


--================================================================================
--DQL: 10 Business Case Stuies
--================================================================================

-- 1. All distinct cities in the state of 'SP' (São Paulo).

select
	distinct customer_city as cities_in_sp
from customers
where customer_state = 'SP' 
order by customer_city asc;

--2. What is the total volume of orders distributed across each fulfillment state (e.g., delivered, shipped, canceled), and which statuses account for the highest operational load?
select
	order_status,
	count (*) as total_orders
from orders
where 
	order_status in('delivered', 'canceled', 'shipped') 
group by order_status
order by total_orders desc;

--3. Find the top 10 most expensive items sold by unit price (price). 
select
	order_id,
	product_id,
	price
from order_items
order by price desc
limit 10;

--4. For each payment_type (e.g., credit_card, boleto, voucher), calculate:
	--Total transaction volume .
	--Total revenue collected .
	--Average transaction amount.

select
	payment_type,
	count(*) as total_transactions,
	round(sum(payment_value)::numeric,2) as total_revenue,
	round(avg(payment_value)::numeric,2) as avg_payment_value
from
	order_payments
where 
	payment_type in ('credit_card', 'boleto', 'voucher')
group by 
	payment_type
order by 
	total_transactions desc;


--5. Find the otal number of reviews for each review_score (1 to 5). 
--Include how many of those reviews included a written comment.

select
	review_score,
	count(*) as total_reviews,
	COUNT(review_comment_message) AS reviews_with_comments	
from
	order_reviews
group by
	review_score
order by
	review_score asc;

--6. Average delivery duration (in days) to the customer. (Filter only for delivered orders with valid delivery dates)

select
	round(avg(order_delivered_customer_date::date - order_purchase_timestamp::date),1) as avg_delivery_duration_days
from
	orders
where
	order_status='delivered' and
	order_delivered_customer_date is not null;


--7. All Brazilian states that have placed more than 3,000 delivered orders. 

SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM
    orders o
JOIN
    customers c ON o.customer_id = c.customer_id
WHERE
    o.order_status = 'delivered'
GROUP BY
    c.customer_state
HAVING
    COUNT(DISTINCT o.order_id) > 3000
ORDER BY
    total_orders DESC;	

--8. What are the top 5 product categories generating the highest total sales revenue (excluding products without a category)? 

select * from vw_products;

select 
	vp.product_category as category_name,
	round(sum(oi.price)::numeric,2) as total_revenue
from order_items as oi
join vw_products as vp
	on oi.product_id = vp.product_id
where
	vp.product_category is not null
group by 
	vp.product_category
order by
	total_revenue desc
limit 5;

--9. How many sold items fall into a 'High Shipping' bracket (where shipping cost exceeds the item price) versus 'Standard Shipping'?

select
case
	when freight_value > price then 'High Shipping'
	else 'Standard Shipping' 
end as shipping_category,
count(*) as total_items
from order_items
group by shipping_category
order by total_items desc;

--10. For orders delivered past their estimated arrival date,  calculate:
	--The total count of late orders.
	--The average number of days overdue (rounded to 1 decimal place).
	--The maximum number of days an order was delayed.


SELECT
    COUNT(*) AS total_late_orders,
    ROUND(AVG(order_delivered_customer_date::DATE - order_estimated_delivery_date::DATE)::NUMERIC, 1) AS avg_days_overdue,
    MAX(order_delivered_customer_date::DATE - order_estimated_delivery_date::DATE) AS max_days_delayed
FROM
    orders
WHERE
    order_delivered_customer_date > order_estimated_delivery_date;

