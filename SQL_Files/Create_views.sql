Select TOP 10 * FROM stg.orders

Select *
From INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'stg.orders'

Select TOP 10 * FROM stg.products


Select TOP 10 * FROM stg.order_items

Select TOP 10 * FROM stg.customers

select p.price, oi.quantity, oi.unit_price,p.stock_quantity
from stg.products p
join stg.order_items oi
ON p.product_id = oi.product_id


CREATE VIEW vw_customers
AS
SELECT customer_id, first_name,
	last_name, email, country, 
	city, marketing_opt_in, 
	customer_segment, repeat_customer
FROM stg.customers

select * from vw_customers




CREATE VIEW vw_orders
AS
SELECT order_id, order_date,
	order_status, payment_status,
	payment_method, device_type,
	traffic_source
FROM stg.orders

select * from vw_orders

ALTER VIEW vw_orders AS
SELECT order_id, order_status, payment_status,
		payment_method, device_type, traffic_source
	FROM stg.orders

CREATE VIEW vw_products
AS
SELECT product_id, product_name,
	category, brand, active
FROM stg.products

select * from vw_products


CREATE VIEW vw_facts
AS
SELECT oi.order_item_id, oi.order_id,
	oi.product_id, oi.customer_id,
	oi.quantity, p.price, p.cost
FROM stg.order_items oi
JOIN stg.products p
ON oi.product_id = p.product_id


select * from vw_facts


ALTER VIEW vw_facts AS
SELECT oi.order_item_id, oi.order_id,
	oi.product_id, oi.customer_id,
	oi.quantity, p.price, p.cost, o.order_date
FROM stg.order_items oi
JOIN stg.orders o
    ON oi.order_id = o.order_id
JOIN stg.products p
    ON oi.product_id = p.product_id;
