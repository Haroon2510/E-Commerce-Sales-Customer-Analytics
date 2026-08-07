
SELECT * FROM vw_customers

-- creating procedure "how many customers opted for marketing"



CREATE PROCEDURE GetMarketedCustomers
@market bit
AS
BEGIN
SELECT COUNT(*) as Marketed_Customers FROM vw_customers
WHERE marketing_opt_in = @market
END


DROP PROCEDURE IF EXISTS GetMarketedCustomers

EXEC GetMarketedCustomers @market = 1


-- creating procedure "customers per country"

CREATE PROCEDURE GetCustomersbyCountry
@country NVARCHAR(50)
AS
BEGIN
SELECT first_name, last_name, country
FROM vw_customers
WHERE country = @country
END


EXEC GetCustomersbyCountry @country = Indonesia


---- How many orders did they receive

CREATE PROCEDURE GetOrders
AS
BEGIN
SELECT COUNT(*) as total_orders FROM vw_orders
END




-- Aggregation Procedures

-- 1) get monthly sales
CREATE PROCEDURE GetMonthlySales
AS
BEGIN
SELECT  YEAR(o.order_date) AS SalesYear,
		MONTH(o.order_date) AS SalesMonth,
		DATENAME(MONTH,o.order_date) AS Month_Name,
		SUM(f.quantity * f.price) AS TotalSales,
		SUM(f.quantity * f.cost) AS TotalCost,
		SUM(f.quantity * (f.price-f.cost)) AS TotalProfit,
		SUM(f.quantity) AS TotalQuantity
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date), DATENAME(MONTH,o.order_date)
ORDER BY SalesYear, SalesMonth;
END


-- 2) get quarterly sales

CREATE PROCEDURE GetQuarterlySales
AS
BEGIN
SELECT	YEAR(o.order_date) AS SalesYear,
		DATEPART(QUARTER, o.order_date) Quarter,
		SUM(f.quantity * f.price) TotalSales,
		SUM(f.quantity * (f.price-f.cost)) Profit
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY YEAR(o.order_date), DATEPART(QUARTER,o.order_date)
ORDER BY SalesYear, Quarter;
END

-- 3) get yearly sales


CREATE PROCEDURE GetYearlySales
AS
BEGIN
SELECT  YEAR(o.order_date) SalesYear,
		SUM(f.quantity * f.price) Sales,
		SUM(f.quantity * (f.price-f.cost)) Profit
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY YEAR(o.order_date);
END


-- 4) get category performance

CREATE PROCEDURE GetCategoryPerformance
AS
BEGIN
SELECT  p.category,
		SUM(f.quantity * f.price) Sales,
		SUM(f.quantity * (f.price-f.cost)) Profit,
		SUM(f.quantity) QuantitySold
FROM vw_facts f
JOIN vw_products p
ON f.product_id=p.product_id
GROUP BY p.category
ORDER BY Sales DESC;
END



-- 5) Get sales by country

CREATE PROCEDURE GetSalesbyCountry
AS
BEGIN
SELECT  c.country,
		SUM(f.quantity * f.price) Sales,
		SUM(f.quantity * (f.price-f.cost)) Profit
FROM vw_facts f
JOIN vw_customers c
ON f.customer_id=c.customer_id
GROUP BY c.country
ORDER BY Sales DESC;
END



-- 6) get sales by customer_segment


CREATE PROCEDURE GetSalesbyCustomerSegment
AS
BEGIN
SELECT  c.customer_segment,
		SUM(f.quantity * f.price) Sales,
		COUNT(DISTINCT c.customer_id) Customers
FROM vw_facts f
JOIN vw_customers c
ON f.customer_id=c.customer_id
GROUP BY customer_segment;
END



-- Analytical Procedures

-- for running total

CREATE PROCEDURE RunningTotal
AS
BEGIN
SELECT  o.order_date,
		SUM(f.quantity * f.price) DailySales,
		SUM(SUM(f.quantity * f.price)) OVER(
		ORDER BY o.order_date) RunningTotal
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id 
GROUP BY o.order_date 
ORDER BY o.order_date;
END


-- monthly rank

CREATE PROCEDURE MonthlyRank
AS
BEGIN
SELECT  YEAR(o.order_date) SalesYear,
		MONTH(o.order_date) SalesMonth,
		SUM(f.quantity * f.price) Sales,
		RANK() OVER(ORDER BY SUM(f.quantity * f.price) DESC) SalesRank
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date);
END


-- category ranking

CREATE PROCEDURE CategoryRanking
AS
BEGIN
SELECT  p.category,
		SUM(f.quantity * f.price) Sales,
		RANK() OVER(ORDER BY SUM(f.quantity * f.price) DESC) ProductRank
FROM vw_facts f
JOIN vw_products p
ON f.product_id=p.product_id
GROUP BY p.category;
END


-- previous day sales

CREATE PROCEDURE PreviousDaySales
AS
BEGIN
SELECT  o.order_date,
		SUM(f.quantity * f.price) Sales,
		LAG(SUM(f.quantity * f.price)) OVER(
			ORDER BY o.order_date) PreviousDaySales
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY o.order_date;
END


-- moving average

CREATE PROCEDURE MovingAverage
AS
BEGIN
SELECT  o.order_date,
		SUM(f.quantity * f.price) Sales,
		AVG(SUM(f.quantity * f.price)) OVER(
			ORDER BY o.order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) MovingAverage
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
GROUP BY o.order_date;
END



-- ranking of top customers



SELECT  c.customer_id, c.first_name,
		SUM(f.quantity * f.price) Sales,
		DENSE_RANK() OVER(
			ORDER BY SUM(f.quantity * f.price) DESC) CustomerRank
FROM vw_facts f
JOIN vw_customers c
ON f.customer_id=c.customer_id
GROUP BY c.customer_id, c.first_name;


-- Business Procedures

-- customer history

CREATE PROCEDURE CustomerHistory
@CustomerID INT
AS
SELECT * FROM vw_customers 
WHERE customer_id=@CustomerID;


EXEC CustomerHistory @CustomerID = 2000


DROP PROCEDURE IF EXISTS CustomerHistory


-- order by status


CREATE PROCEDURE OrdersByStatus
@Status VARCHAR(50)
AS
SELECT * FROM vw_orders
WHERE order_status=@Status;

EXEC OrdersByStatus @status = Returned


SELECT * FROM vw_orders


-- customer orders


CREATE PROCEDURE CustomerOrders
@CustomerID INT
AS
SELECT	o.order_id, o.order_date,
		f.quantity, f.price
FROM vw_orders o
JOIN vw_facts f
ON o.order_id=f.order_id
WHERE f.customer_id=@CustomerID;

select * FROM vw_facts

EXEC CustomerOrders @CustomerID = 2133


-- category sales


CREATE PROCEDURE CategorySales
@Category VARCHAR(50)
AS
SELECT	p.category,
		SUM(f.quantity * f.price) Sales
FROM vw_facts f
JOIN vw_products p
ON f.product_id=p.product_id
WHERE p.category=@Category
GROUP BY p.category;


EXEC CategorySales @Category = Clothing

SELECT * FROM vw_products


 --- sales by device

 CREATE PROCEDURE SalesByDevice
@Device VARCHAR(50)
AS
SELECT	o.device_type,
		SUM(f.quantity * f.price) Sales
FROM vw_facts f
JOIN vw_orders o
ON f.order_id=o.order_id
WHERE o.device_type=@Device
GROUP BY o.device_type;


EXEC SalesByDevice @Device = Desktop