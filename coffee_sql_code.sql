-- OBJECTIVE
-- Which country performed highest and which lowest?
-- What are the highest quarterly and monthly performance for each country (understanding seasonal trend)?
-- How each coffee variation is performing under each country?
-- Who are the top buyer and their country of origin?
-- How each roast type is performing monthly and quarterly?
-- How each roast is performing under each coffee variation and country?
-- Which coffee variation performed highest based on quarterly and monthly performance?
-- What are the historical sales from loyalty cardholder and Y/Y changes?


-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------

-- Which country performed highest and which lowest?
WITH CTE_COUNTRY_PERFORMANCE AS (
SELECT 
	  DISTINCT(COUNTRY) AS COUNTRY,
      YEAR(ORDER_DATE) AS YEAR,
      ROUND(SUM(QUANTITY*UNIT_PRICE),2) AS SALES,
      CONCAT('$',ROUND(SUM(SUM(QUANTITY*UNIT_PRICE)) OVER (PARTITION BY COUNTRY ORDER BY YEAR(ORDER_DATE) ),2)) AS RUNNING_TOTAL_MONTHLY
FROM CUSTOMER C
JOIN ORDERS O
ON C.CUSTOMER_ID = O.CUSTOMER_ID
JOIN PRODUCT P
ON O.PRODUCT_ID = P.PRODUCT_ID
GROUP BY COUNTRY, YEAR(ORDER_DATE)
)
SELECT 
      COUNTRY,
      YEAR,
      SALES,
      RUNNING_TOTAL_MONTHLY,
      CONCAT(ROUND((SALES - LAG(SALES) OVER (PARTITION BY COUNTRY ORDER BY YEAR)) / LAG(SALES) OVER (PARTITION BY COUNTRY ORDER BY YEAR) * 100,2),'%') AS DIFFERENCES
FROM CTE_COUNTRY_PERFORMANCE;


-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- What are the highest quarterly and monthly performance for each country (understanding seasonal trend)?

-- QUARTERLY
SELECT
      DISTINCT (COUNTRY),
      QUARTER (ORDER_DATE) AS QUARTERLY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES
FROM CUSTOMER
JOIN ORDERS 
USING (CUSTOMER_ID)
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY COUNTRY, QUARTER(ORDER_DATE)
ORDER BY COUNTRY;

-- MONTHLY 
SELECT
      DISTINCT (COUNTRY),
      MONTH (ORDER_DATE) AS MONTHLY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES
FROM CUSTOMER
JOIN ORDERS 
USING (CUSTOMER_ID)
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY COUNTRY, MONTH(ORDER_DATE)
ORDER BY COUNTRY;

-- MONTHLY AND QUARTERLY COMBINED
SELECT
      DISTINCT (COUNTRY),
      QUARTER (ORDER_DATE) AS QUARTERLY,
      MONTH (ORDER_DATE) AS MONTHLY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES
FROM CUSTOMER
JOIN ORDERS 
USING (CUSTOMER_ID)
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY COUNTRY, QUARTER (ORDER_DATE), MONTH(ORDER_DATE)
ORDER BY COUNTRY;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- How each coffee variation is performing under each country?
SELECT 
      DISTINCT(COUNTRY),
      COFFEE_TYPE,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES,
      DENSE_RANK () OVER (PARTITION BY COUNTRY ORDER BY SUM(QUANTITY*UNIT_PRICE)) as SALES_RANK
FROM CUSTOMER
JOIN ORDERS 
USING (CUSTOMER_ID)
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY COUNTRY, COFFEE_TYPE
ORDER BY COUNTRY;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Who are the top customers and their country of origin?
SELECT 
      DISTINCT(CUSTOMER_ID),
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES,
      COUNTRY
FROM CUSTOMER
JOIN ORDERS 
USING (CUSTOMER_ID)
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY CUSTOMER_ID, COUNTRY
ORDER BY SUM(QUANTITY*UNIT_PRICE) DESC
LIMIT 10;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
 -- How each roast type is performing monthly and quarterly?     
SELECT
      DISTINCT (ROAST_TYPE),
      QUARTER (ORDER_DATE) AS QUARTERLY,
      MONTH (ORDER_DATE) AS MONTHLY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES,
      CONCAT('$',ROUND(SUM(SUM(QUANTITY*UNIT_PRICE)) OVER (PARTITION BY ROAST_TYPE ORDER BY MONTH(ORDER_DATE)),2)) AS RUNNING_TOTAL_MONTHLY
FROM ORDERS 
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY ROAST_TYPE, QUARTER (ORDER_DATE), MONTH(ORDER_DATE)
ORDER BY ROAST_TYPE;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- How each roast is performing under each coffee variation and country?
SELECT
      DISTINCT (ROAST_TYPE),
      COFFEE_TYPE,
      COUNTRY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES
FROM ORDERS 
JOIN PRODUCT
USING (PRODUCT_ID)
JOIN CUSTOMER
USING (CUSTOMER_ID)
GROUP BY ROAST_TYPE, COFFEE_TYPE, COUNTRY
ORDER BY ROAST_TYPE;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- Which coffee variation performed best based on quarterly and monthly performance?
SELECT
      DISTINCT (COFFEE_TYPE),
      QUARTER (ORDER_DATE) AS QUARTERLY,
      MONTH (ORDER_DATE) AS MONTHLY,
      CONCAT('$',ROUND(SUM(QUANTITY*UNIT_PRICE),2)) AS SALES,
      CONCAT('$',ROUND(SUM(SUM(QUANTITY*UNIT_PRICE)) OVER (PARTITION BY COFFEE_TYPE ORDER BY MONTH(ORDER_DATE)),2)) AS RUNNING_TOTAL_MONTHLY
FROM ORDERS 
JOIN PRODUCT
USING (PRODUCT_ID)
GROUP BY COFFEE_TYPE, QUARTER (ORDER_DATE), MONTH(ORDER_DATE)
ORDER BY COFFEE_TYPE;

-------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------
-- What are the historical sales from loyalty cardholder and Y/Y changes?
WITH CTE_LOYALTY_SALES AS (
SELECT 
	  DISTINCT(LOYALTY_CARD) AS CARD_HOLDER,
      YEAR(ORDER_DATE) AS YEAR,
      COUNT(LOYALTY_CARD) AS LOYALTY_COUNT,
      ROUND(SUM(QUANTITY*UNIT_PRICE),2) AS SALES
FROM ORDERS 
JOIN PRODUCT
USING (PRODUCT_ID)
JOIN CUSTOMER
USING (CUSTOMER_ID)
GROUP BY LOYALTY_CARD, YEAR(ORDER_DATE)
ORDER BY LOYALTY_CARD
)
SELECT 
      *,
      CONCAT(ROUND((SALES-LAG(SALES) OVER (PARTITION BY CARD_HOLDER ORDER BY YEAR)) / LAG(SALES) OVER (PARTITION BY CARD_HOLDER ORDER BY YEAR) * 100,2),'%') AS DIFFERENCES
FROM CTE_LOYALTY_SALES;

-- LOYALTY CARD HOLDER DISTRIBUTION 
WITH CTE_YES_LOYALTY AS (
SELECT 
      COUNT(Loyalty_Card) AS YES_LOYALTY
FROM customer
WHERE Loyalty_Card = 'YES'
),
CTE_NO_LOYALTY AS(
SELECT COUNT(LOYALTY_CARD) AS NO_LOYALTY
FROM customer
WHERE Loyalty_Card = 'NO'
),
CTE_COUNT AS(
SELECT 
      COUNT(Loyalty_Card) AS COUNT
FROM customer
)
SELECT 
      DISTINCT (LOYALTY_CARD),
      COUNT(LOYALTY_CARD),
      CONCAT(ROUND(CASE
	  WHEN LOYALTY_CARD = 'YES' THEN YES_LOYALTY / COUNT * 100 
      WHEN LOYALTY_CARD = 'NO' THEN NO_LOYALTY / COUNT * 100
      END,2),'%') AS PERCENTAGE
FROM  CUSTOMER
JOIN CTE_YES_LOYALTY
JOIN CTE_NO_LOYALTY
JOIN CTE_COUNT
GROUP BY Loyalty_Card, YES_LOYALTY, NO_LOYALTY, COUNT;
	