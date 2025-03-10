SELECT *
FROM superstore
;

-- Creating a copy to make changes

CREATE TABLE superstore_staging
LIKE superstore
;


INSERT superstore_staging
SELECT *
FROM superstore
;


SELECT *
FROM superstore_staging
;

-- Correct column names and data formats


ALTER TABLE superstore_staging
ADD COLUMN order_date DATE
;

UPDATE superstore_staging
SET order_date = STR_TO_DATE(`ORDER DATE`, '%d-%m-%Y')
;

ALTER TABLE superstore_staging
ADD COLUMN ship_date DATE
;


UPDATE superstore_staging
SET ship_date = STR_TO_DATE(`Ship Date`, '%d-%m-%Y')
;


ALTER TABLE superstore_staging
DROP COLUMN `Order Date`,
DROP COLUMN `Ship Date`
;


ALTER TABLE superstore_staging
CHANGE COLUMN `Row ID` row_id INT,
CHANGE COLUMN `ORDER ID` order_id VARCHAR(255),
CHANGE COLUMN `Ship Mode` ship_mode VARCHAR(255),
CHANGE COLUMN `Customer ID` customer_id VARCHAR(255),
CHANGE COLUMN `Customer Name` customer_name VARCHAR(255),
CHANGE COLUMN `Segment` segment VARCHAR(255),
CHANGE COLUMN `Country` country VARCHAR(255),
CHANGE COLUMN `City` city VARCHAR(255),
CHANGE COLUMN `State` state VARCHAR(255),
CHANGE COLUMN `Postal Code` postal_code INT,
CHANGE COLUMN `Region` region VARCHAR(255),
CHANGE COLUMN `Product ID` product_id VARCHAR(255),
CHANGE COLUMN `Category` category VARCHAR(255),
CHANGE COLUMN `Sub-Category` sub_category VARCHAR(255),
CHANGE COLUMN `Product Name` product_name VARCHAR(255),
CHANGE COLUMN `Sales` sales DECIMAL(10,4),
CHANGE COLUMN `Quantity` quantity INT,
CHANGE COLUMN `Discount` discount DECIMAL(10,2),
CHANGE COLUMN `Profit` profit DECIMAL(10,4)
;


-- Total Sales

SELECT SUM(Sales) AS total_sales
FROM superstore_staging
;


-- Total Sales by year

SELECT YEAR(order_date) AS year, SUM(Sales) AS total_sales
FROM superstore_staging
GROUP BY year
;


-- Top 5 Most Sold Products and Categories Based on Revenue and Quantity

SELECT product_name, category, sub_category, SUM(sales) AS revenue, SUM(quantity) AS total_quantity
FROM superstore_staging
GROUP BY product_name, category, sub_category
ORDER BY revenue DESC
LIMIT 5
;

SELECT sub_category, SUM(sales) AS revenue, SUM(quantity) AS total_quantity
FROM superstore_staging
GROUP BY sub_category
ORDER BY revenue DESC
LIMIT 5
;

SELECT product_name, category, sub_category, SUM(sales) AS revenue, SUM(quantity) AS total_quantity
FROM superstore_staging
GROUP BY product_name, category, sub_category
ORDER BY total_quantity DESC
LIMIT 5
;


SELECT sub_category, SUM(sales) AS revenue, SUM(quantity) AS total_quantity
FROM superstore_staging
GROUP BY sub_category
ORDER BY total_quantity DESC
LIMIT 5
;


-- Sales trend analysis

SELECT DATE_FORMAT(order_date, '%m-%Y') AS month_year, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY YEAR(order_date), MONTH(order_date), month_year
ORDER BY YEAR(order_date), MONTH(order_date)
;

SELECT YEAR(order_date) AS year, MONTH(order_date) AS month, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY year, month
ORDER BY total_sales DESC
;


SELECT QUARTER(order_date) AS quarter, YEAR(order_date) AS year, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY quarter, year
ORDER BY total_sales DESC
;


SELECT category, MONTH(order_date) AS month, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY category, month
ORDER BY category, total_sales DESC
;


-- Year on Year Monthly Sales

SELECT YEAR(order_date) AS year, MONTH(order_date) AS month, SUM(sales) AS total_sales,
LAG(SUM(sales)) OVER(PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date)) AS prev_year_sales,
(SUM(sales) - LAG(SUM(sales)) OVER(PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date))) / LAG(SUM(sales)) OVER(PARTITION BY MONTH(order_date) ORDER BY YEAR(order_date)) * 100.0 AS yoy_growth
FROM superstore_staging
GROUP BY year, month
;

SELECT *
FROM superstore_staging
;

-- Sales by city, state and region

SELECT city, state, region, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY city, state, region
ORDER BY total_sales DESC
;

SELECT region, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY region
ORDER BY total_sales DESC
;


SELECT city, SUM(sales) AS total_sales
FROM superstore_staging
GROUP BY city
ORDER BY total_sales DESC
;



-- Customer analysis

SELECT customer_name, SUM(sales) AS total_sales, COUNT(order_id) AS total_orders, AVG(sales) AS avg_order_value
FROM superstore_staging
GROUP BY customer_name
ORDER BY total_sales DESC
;


-- Repeat Purchases

SELECT customer_id, customer_name,
COUNT(order_id) AS total_orders,
SUM(sales) AS total_sales, 
AVG(sales) AS avg_order_value
FROM superstore_staging
GROUP BY customer_id, customer_name
HAVING COUNT(*) > 1
ORDER BY total_orders DESC
;


WITH cte AS (
SELECT customer_id, MIN(order_date) AS first_order_date
FROM superstore_staging
GROUP BY customer_id
)

SELECT YEAR(order_date) AS year, MONTH(order_date) AS month,
COUNT(DISTINCT CASE WHEN order_date = first_order_date THEN ss.customer_id END) AS new_customers,
COUNT(DISTINCT CASE WHEN order_date > first_order_date THEN ss.customer_id END) AS repeat_customers
FROM superstore_staging ss
JOIN cte c
ON ss.customer_id = c.customer_id
GROUP BY year, month
ORDER BY year, month
;


-- Profit Margins across products

SELECT product_name, category, sub_category, 
SUM(sales) AS total_sales, 
SUM(profit) AS total_profit, 
(SUM(profit) / SUM(sales)) * 100 AS profit_margin
FROM superstore_staging
GROUP BY product_name, category, sub_category
ORDER BY profit_margin DESC
;


-- Discount Analysis

SELECT discount, 
COUNT(order_id) AS total_orders,
SUM(sales) AS total_sales, 
SUM(profit) AS total_profit, 
(SUM(profit) / SUM(sales)) * 100 AS profit_margin
FROM superstore_staging
GROUP BY discount
ORDER BY profit_margin DESC
;


-- Shipping Performance

SELECT ship_mode,
COUNT(order_id) AS total_orders,
SUM(sales) AS total_sales, 
SUM(profit) AS total_profit, 
(SUM(profit) / SUM(sales)) * 100 AS profit_margin,
AVG(DATEDIFF(ship_date, order_date)) AS avg_delivery_days
FROM superstore_staging
GROUP BY ship_mode
;


