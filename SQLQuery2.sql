USE apple_database

--Q1

SELECT country, COUNT(store_id) AS Total_Stores
FROM stores
GROUP BY country
ORDER BY Total_Stores DESC;

--Q2

SELECT a.store_id, a.store_name,
SUM(quantity) AS total_units_sold
FROM sales AS b
INNER JOIN stores AS a
ON a.store_id = b.store_id
GROUP BY a.store_id,a.store_name
ORDER BY total_units_sold DESC;

--Q3

SELECT SUM(quantity) AS total_sales
FROM sales
WHERE YEAR(sale_date) = 2023 AND MONTH(sale_date) = 12;

--Q4

SELECT store_id, store_name FROM stores
WHERE store_id NOT IN (
		SELECT a.store_id FROM stores AS a
		INNER JOIN sales AS b
		ON a.store_id = b.store_id
		INNER JOIN warranty AS c
		ON b.sale_id = c.sale_id )
ORDER BY store_id ASC;

--Q5

SELECT 
    ROUND (CAST(COUNT(claim_id) AS FLOAT) / 
    CAST((SELECT COUNT(claim_id) FROM warranty) AS FLOAT) * 100, 4) AS percentage
FROM warranty
WHERE repair_status = 'Warranty Void';

--Q6

SELECT a.store_id, a.store_name, SUM(b.quantity) AS total_sales
FROM stores AS a
INNER JOIN sales AS b
ON a.store_id = b.store_id
WHERE YEAR(sale_date) = '2023'
GROUP BY a.store_id, a.store_name
ORDER BY total_sales DESC;

--Q7

SELECT a.product_id, a.product_name, SUM(b.quantity) AS total_sales
FROM products AS a
INNER JOIN sales AS b
ON a.product_id = b.product_id
WHERE YEAR(sale_date) = '2023'
GROUP BY a.product_id, a.product_name
ORDER BY total_sales DESC;

--Q8

SELECT a.category_id, a.category_name, ROUND(AVG(CAST((b.price) AS FLOAT)),2)AS avg_price
FROM category AS a
INNER JOIN products AS b
ON a.category_id = b.category_id
GROUP BY a.category_id, a.category_name
ORDER BY avg_price DESC;

--Q9

SELECT ISNULL(repair_status, 'total_claims') AS repair_status, COUNT(*) AS warranty_claims
FROM warranty
WHERE YEAR(claim_date) = '2020'
GROUP BY repair_status WITH ROLLUP;

--Q10

WITH cte AS 
	(
	SELECT a.store_id, a.store_name,
	DATENAME(WEEKDAY, b.sale_date) AS best_selling_day, SUM(b.quantity) AS total_sales,
	RANK () OVER (PARTITION BY a.store_id ORDER BY SUM(b.quantity) DESC) AS rank
	FROM stores AS a
	INNER JOIN sales AS b
	ON a.store_id = b.store_id
	GROUP BY a.store_id, a.store_name, DATENAME(WEEKDAY, b.sale_date)
	)

Select store_id, store_name, best_selling_day, total_sales FROM cte
WHERE rank = 1;

--Q11

WITH cte AS 
	(
	SELECT a.product_id, a.product_name, SUM(b.quantity) AS total_sales,
	YEAR(b.sale_date) AS sale_year, c.country,
	RANK() OVER (PARTITION BY c.country, YEAR(b.sale_date) ORDER BY YEAR(b.sale_date), SUM(b.quantity)) AS rank
	FROM products AS a
	INNER JOIN sales AS b
	ON a.product_id = b.product_id
	INNER JOIN stores AS c
	ON b.store_id = c.store_id
	GROUP BY a.product_id, a.product_name, YEAR(b.sale_date), c.country
	)
SELECT * FROM cte
WHERE rank = 1;

--Q12

SELECT COUNT(a.claim_id) AS warranty_claims
FROM warranty AS a
INNER JOIN sales AS b
ON a.sale_id = b.sale_id
WHERE DATEDIFF(DAY, b.sale_date, a.claim_date) <= 180;

--Q13

SELECT c.product_name, COUNT(a.claim_id) AS warranty_claims, SUM(b.quantity) AS total_sales
FROM warranty AS a
RIGHT JOIN sales AS b
ON a.sale_id = b.sale_id
INNER JOIN products AS c
ON b.product_id = c.product_id
WHERE YEAR(c.launch_date) IN (2022, 2023)
GROUP BY product_name
HAVING COUNT(a.claim_id) > 0
ORDER BY product_name;

--Q14

SELECT FORMAT(a.sale_date, 'MM-yyyy') AS month, SUM(a.quantity) AS total_sales
FROM sales AS a
JOIN stores AS b
ON a.store_id = b.store_id
WHERE b.country = 'USA' 
	AND YEAR(a.sale_date) IN (2022,2023,2024)
GROUP BY FORMAT(a.sale_date, 'MM-yyyy')
HAVING SUM(a.quantity) > 1000
ORDER BY month;

--Q15

SELECT a.category_id, a.category_name, COUNT(d.claim_id) AS warranty_claims
FROM category AS a
INNER JOIN products AS b
ON a.category_id = b.category_id
INNER JOIN sales AS c
ON b.product_id = c.product_id
INNER JOIN warranty AS d
ON c.sale_id = d.sale_id
WHERE YEAR(d.claim_date) IN (2023,2024)
GROUP BY a.category_id, a.category_name
ORDER BY warranty_claims DESC;

--Q16

SELECT 
a.country,
SUM(b.quantity) AS total_sales, 
COUNT(c.claim_id) AS warranty_claims,
	CASE 
		WHEN CAST(COUNT(c.claim_id) AS FLOAT) / CAST(SUM(b.quantity) AS FLOAT) * 100 = 0 
        THEN 'No Claim Chance'
        ELSE CAST(ROUND(CAST(COUNT(c.claim_id) AS FLOAT) / CAST(SUM(b.quantity) AS FLOAT) * 100, 2) AS VARCHAR)
    END AS percentage_chance
FROM stores AS a
INNER JOIN sales AS b
ON a.store_id = b.store_id
LEFT JOIN warranty AS c
ON b.sale_id = c.sale_id
GROUP BY a.country
ORDER BY a.country;

--Q17 Analyze the year-by-year growth ratio for each store.

WITH cte AS (
	SELECT a.store_id, a.store_name, YEAR(b.sale_date) AS year, (SUM(b.quantity * c.price)) AS total_sales
	FROM stores AS a
	INNER JOIN sales AS b
	ON a.store_id = b.store_id
	INNER JOIN products AS c
	ON b.product_id = c.product_id
	GROUP BY a.store_id, a.store_name, YEAR(b.sale_date)
	),

cte2 AS (
	SELECT store_id, store_name, year, total_sales AS current_year_sales,
	LAG(total_sales, 1) OVER (PARTITION BY store_name ORDER BY year) AS previous_year_sales
	FROM cte
	),

cte3 AS (
	SELECT store_id, store_name, year, current_year_sales, previous_year_sales,
		ROUND(CAST((current_year_sales - previous_year_sales) AS FLOAT) / CAST(previous_year_sales AS FLOAT) 
		* 100, 2)
		AS growth_rate
	FROM cte2
	WHERE previous_year_sales IS NOT NULL
	),

cte4 AS (
	SELECT store_id, store_name, year, FORMAT(current_year_sales, 'N0') AS current_year_sales,
	FORMAT(previous_year_sales, 'N0') AS previous_year_sales, growth_rate
	FROM cte3
	)
SELECT store_id, store_name, year, current_year_sales, previous_year_sales, growth_rate,
CASE
	WHEN growth_rate > 0 THEN 'GROWTH'
	ELSE 'DECLINE' 
	END AS status
FROM cte4
ORDER BY store_name, year;

--Q18

WITH cte AS (
	SELECT
	CASE
		WHEN c.price < 500 THEN 'LOW RANGE PRODUCT'
		WHEN c.price BETWEEN 500 AND 1000 THEN 'MID RANGE PRODUCT'
		ELSE 'HIGH RANGE PRODUCT'
	END AS range,
	c.price AS price_range,
	a.claim_id AS total_claim
	FROM warranty AS a
	lEFT JOIN sales AS b
	ON a.sale_id = b.sale_id
	LEFT JOIN products AS c
	ON b.product_id = c.product_id
	WHERE claim_date >= DATEADD(YEAR, -5, GETDATE())
	)
SELECT range AS product_range, price_range, COUNT(total_claim) AS total_warranty_claims
FROM cte
WHERE price_range IS NOT NULL
GROUP BY range, price_range
ORDER BY price_range;

--Q19

WITH cte AS (

	SELECT a.store_id, a.store_name, COUNT(c.repair_status) AS total_claims,
	COUNT(
		CASE WHEN c.repair_status = 'Paid Repaired' THEN 1 END) AS total_paid_repaired
	FROM stores AS a
	INNER JOIN sales AS b
	ON a.store_id = b.store_id
	INNER JOIN warranty AS c
	ON b.sale_id = c.sale_id
	GROUP BY a.store_id, a.store_name
	)

SELECT store_id, store_name, total_claims, total_paid_repaired,
ROUND((CAST(total_paid_repaired AS FLOAT) / CAST(total_claims AS FLOAT)) * 100, 3) 
AS percent_of_total_claims
FROM cte
WHERE total_paid_repaired != 0
ORDER BY percent_of_total_claims DESC;

--Q20

WITH cte AS (

	SELECT a.store_id, a.store_name, DATENAME(MONTH,b.sale_date) AS month, 
	MONTH(b.sale_date) AS month_number, YEAR(b.sale_date) AS year,
	SUM(c.price * b.quantity) AS revenue
	FROM stores AS a
	INNER JOIN sales AS b
	ON a.store_id = b.store_id
	INNER JOIN products AS c
	ON b.product_id = c.product_id
	GROUP BY a.store_id, a.store_name, DATENAME(MONTH,b.sale_date), 
	MONTH(b.sale_date), YEAR(b.sale_date)
	)

SELECT store_id, store_name, month, year, FORMAT(revenue, 'N0') AS revenue,
FORMAT(SUM(revenue) OVER (PARTITION BY store_id ORDER BY year, month_number),'N0') AS running_total
FROM cte
ORDER BY store_name, year, month_number;

--Q21

SELECT a.product_name, 
CASE
	WHEN b.sale_date BETWEEN a.launch_date AND DATEADD(MONTH, 6, a.launch_date) THEN '0-6 months'
	WHEN b.sale_date BETWEEN DATEADD(MONTH, 6, a.launch_date) AND DATEADD(MONTH, 12, a.launch_date) THEN '6-12 months'
	WHEN b.sale_date BETWEEN DATEADD(MONTH, 12, a.launch_date) AND DATEADD(MONTH, 18, a.launch_date) THEN '12-18 months'
	ELSE '18+ months'
END AS launch_sale_interval,
SUM(b.quantity) AS total_sales
FROM products AS a
INNER JOIN sales AS b
ON a.product_id = b.product_id
GROUP BY a.product_name,
CASE
	WHEN b.sale_date BETWEEN a.launch_date AND DATEADD(MONTH, 6, a.launch_date) THEN '0-6 months'
	WHEN b.sale_date BETWEEN DATEADD(MONTH, 6, a.launch_date) AND DATEADD(MONTH, 12, a.launch_date) THEN '6-12 months'
	WHEN b.sale_date BETWEEN DATEADD(MONTH, 12, a.launch_date) AND DATEADD(MONTH, 18, a.launch_date) THEN '12-18 months'
	ELSE '18+ months'
END
ORDER BY a.product_name, total_sales DESC;
