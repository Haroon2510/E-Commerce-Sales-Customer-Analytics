CREATE SCHEMA stg


	  select * from stg.customers

	  ALTER TABLE stg.customers
	  DROP column phone

	  ALTER TABLE stg.customers
	  DROP column created_at

	  DROP TABLE stg.customers


	select * from stg.orders

	select * from stg.products

	select * from stg.order_items


	ALTER TABLE stg.order_items
	  DROP column promo_id