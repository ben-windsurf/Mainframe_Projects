
CREATE TEMP TABLE all_customers AS
SELECT * FROM customer_data;

CREATE TEMP TABLE all_sales AS  
SELECT * FROM sales_data;

CREATE TEMP TABLE customer_countries AS
SELECT DISTINCT COUNTRY, CUSTOMERNAME, PHONE, ADDRESSLINE1, ADDRESSLINE2, 
       CITY, STATE, POSTALCODE, TERRITORY, CONTACTLASTNAME, CONTACTFIRSTNAME,
       ORDERNUMBER
FROM all_customers;

CREATE TEMP TABLE sales_with_extra AS
SELECT s.*, c.COUNTRY, c.CUSTOMERNAME, c.PHONE, c.ADDRESSLINE1, c.ADDRESSLINE2,
       c.CITY, c.STATE, c.POSTALCODE, c.TERRITORY, c.CONTACTLASTNAME, c.CONTACTFIRSTNAME,
       (s.SALES * 1.0) as SALES_DECIMAL,
       (s.QUANTITYORDERED * s.PRICEEACH) as CALCULATED_SALES,
       CASE WHEN s.DEALSIZE = 'Small' THEN 1 
            WHEN s.DEALSIZE = 'Medium' THEN 2 
            ELSE 3 END as DEAL_RANK,
       SUBSTR(s.ORDERDATE, 1, 4) as ORDER_YEAR,
       SUBSTR(s.ORDERDATE, 6, 2) as ORDER_MONTH,
       LENGTH(c.CUSTOMERNAME) as CUSTOMER_NAME_LENGTH,
       UPPER(c.COUNTRY) as COUNTRY_UPPER,
       LOWER(c.TERRITORY) as TERRITORY_LOWER
FROM all_sales s
JOIN all_customers c ON s.ORDERNUMBER = c.ORDERNUMBER;

CREATE TEMP TABLE country_sales_expanded AS
SELECT 
    swe.COUNTRY,
    swe.ORDERNUMBER,
    swe.CUSTOMERNAME,
    swe.PHONE,
    swe.ADDRESSLINE1,
    swe.ADDRESSLINE2,
    swe.CITY,
    swe.STATE,
    swe.POSTALCODE,
    swe.TERRITORY,
    swe.CONTACTLASTNAME,
    swe.CONTACTFIRSTNAME,
    swe.QUANTITYORDERED,
    swe.PRICEEACH,
    swe.ORDERLINENUMBER,
    swe.SALES,
    swe.ORDERDATE,
    swe.STATUS,
    swe.QTR_ID,
    swe.MONTH_ID,
    swe.YEAR_ID,
    swe.PRODUCTLINE,
    swe.MSRP,
    swe.PRODUCTCODE,
    swe.DEALSIZE,
    swe.SALES_DECIMAL,
    swe.CALCULATED_SALES,
    swe.DEAL_RANK,
    swe.ORDER_YEAR,
    swe.ORDER_MONTH,
    swe.CUSTOMER_NAME_LENGTH,
    swe.COUNTRY_UPPER,
    swe.TERRITORY_LOWER,
    cc.COUNTRY as CC_COUNTRY,
    cc.CUSTOMERNAME as CC_CUSTOMERNAME
FROM sales_with_extra swe
JOIN customer_countries cc ON swe.ORDERNUMBER = cc.ORDERNUMBER
WHERE swe.COUNTRY = cc.COUNTRY;

SELECT 
    final_result.COUNTRY,
    SUM(final_result.TOTAL_SALES) as COUNTRY_TOTAL_SALES,
    COUNT(*) as TOTAL_ORDERS,
    AVG(final_result.TOTAL_SALES) as AVG_SALES_PER_ORDER,
    MIN(final_result.TOTAL_SALES) as MIN_SALES,
    MAX(final_result.TOTAL_SALES) as MAX_SALES,
    SUM(final_result.QUANTITYORDERED) as TOTAL_QUANTITY,
    COUNT(DISTINCT final_result.CUSTOMERNAME) as UNIQUE_CUSTOMERS,
    COUNT(DISTINCT final_result.TERRITORY) as UNIQUE_TERRITORIES,
    AVG(final_result.CUSTOMER_NAME_LENGTH) as AVG_CUSTOMER_NAME_LENGTH,
    SUM(final_result.DEAL_RANK) as TOTAL_DEAL_RANK,
    COUNT(CASE WHEN final_result.DEALSIZE = 'Small' THEN 1 END) as SMALL_DEALS,
    COUNT(CASE WHEN final_result.DEALSIZE = 'Medium' THEN 1 END) as MEDIUM_DEALS,
    COUNT(CASE WHEN final_result.DEALSIZE = 'Large' THEN 1 END) as LARGE_DEALS
FROM (
    SELECT DISTINCT
        cse.COUNTRY,
        cse.ORDERNUMBER,
        cse.CUSTOMERNAME,
        cse.PHONE,
        cse.ADDRESSLINE1,
        cse.ADDRESSLINE2,
        cse.CITY,
        cse.STATE,
        cse.POSTALCODE,
        cse.TERRITORY,
        cse.CONTACTLASTNAME,
        cse.CONTACTFIRSTNAME,
        cse.QUANTITYORDERED,
        cse.PRICEEACH,
        cse.ORDERLINENUMBER,
        cse.SALES as TOTAL_SALES,
        cse.ORDERDATE,
        cse.STATUS,
        cse.QTR_ID,
        cse.MONTH_ID,
        cse.YEAR_ID,
        cse.PRODUCTLINE,
        cse.MSRP,
        cse.PRODUCTCODE,
        cse.DEALSIZE,
        cse.SALES_DECIMAL,
        cse.CALCULATED_SALES,
        cse.DEAL_RANK,
        cse.ORDER_YEAR,
        cse.ORDER_MONTH,
        cse.CUSTOMER_NAME_LENGTH,
        cse.COUNTRY_UPPER,
        cse.TERRITORY_LOWER,
        ac1.COUNTRY as AC1_COUNTRY,
        ac2.CUSTOMERNAME as AC2_CUSTOMERNAME,
        als1.SALES as ALS1_SALES,
        als2.QUANTITYORDERED as ALS2_QUANTITY
    FROM country_sales_expanded cse
    JOIN all_customers ac1 ON cse.ORDERNUMBER = ac1.ORDERNUMBER
    JOIN all_customers ac2 ON cse.CUSTOMERNAME = ac2.CUSTOMERNAME
    JOIN all_sales als1 ON cse.ORDERNUMBER = als1.ORDERNUMBER
    JOIN all_sales als2 ON cse.ORDERNUMBER = als2.ORDERNUMBER
    JOIN customer_countries cc1 ON cse.ORDERNUMBER = cc1.ORDERNUMBER
    JOIN customer_countries cc2 ON cse.COUNTRY = cc2.COUNTRY
    WHERE cse.COUNTRY = ac1.COUNTRY
    AND cse.COUNTRY = cc1.COUNTRY
    AND cse.COUNTRY = cc2.COUNTRY
    AND cse.COUNTRY IS NOT NULL
    AND ac1.COUNTRY IS NOT NULL
    AND cc1.COUNTRY IS NOT NULL
    AND cc2.COUNTRY IS NOT NULL
    AND cse.SALES > 0
    AND als1.SALES > 0
    AND als2.SALES > 0
) as final_result
WHERE final_result.COUNTRY IN (
    SELECT DISTINCT c1.COUNTRY 
    FROM all_customers c1
    JOIN all_customers c2 ON c1.COUNTRY = c2.COUNTRY
    WHERE c1.COUNTRY IS NOT NULL
    AND c2.COUNTRY IS NOT NULL
    AND c1.COUNTRY IN (
        SELECT DISTINCT cc.COUNTRY
        FROM customer_countries cc
        WHERE cc.COUNTRY IS NOT NULL
    )
)
AND final_result.TOTAL_SALES IN (
    SELECT s.SALES
    FROM all_sales s
    WHERE s.SALES > 0
)
GROUP BY final_result.COUNTRY, final_result.COUNTRY_UPPER
HAVING COUNT(*) > 0
AND SUM(final_result.TOTAL_SALES) > 0
ORDER BY COUNTRY_TOTAL_SALES DESC, final_result.COUNTRY ASC;

DROP TABLE IF EXISTS all_customers;
DROP TABLE IF EXISTS all_sales;
DROP TABLE IF EXISTS customer_countries;
DROP TABLE IF EXISTS sales_with_extra;
DROP TABLE IF EXISTS country_sales_expanded;
