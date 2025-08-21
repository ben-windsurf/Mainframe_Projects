
CREATE TEMPORARY TABLE temp_all_customers AS
SELECT * FROM customer_data;

CREATE TEMPORARY TABLE temp_all_sales AS  
SELECT * FROM sales_data;

CREATE TEMPORARY TABLE temp_customer_details AS
SELECT 
    c1.*,
    c2.customer_name AS duplicate_name,
    c3.email AS duplicate_email,
    c4.country AS duplicate_country
FROM customer_data c1
CROSS JOIN customer_data c2  -- Unnecessary cross join
CROSS JOIN customer_data c3  -- Another unnecessary cross join  
CROSS JOIN customer_data c4  -- Yet another unnecessary cross join
WHERE c1.customer_id = c2.customer_id
AND c2.customer_id = c3.customer_id
AND c3.customer_id = c4.customer_id;

SELECT 
    c.*,
    s.*,
    tc.*,
    ts.*,
    tcd.*,
    c.country,
    c.country AS country_duplicate,
    UPPER(c.country) AS country_upper,
    LOWER(c.country) AS country_lower,
    CONCAT(c.country, '') AS country_concat,
    (SELECT SUM(s2.sale_amount) 
     FROM sales_data s2 
     JOIN customer_data c2 ON s2.customer_id = c2.customer_id 
     WHERE c2.country = c.country) AS total_sales_subquery,
    s.sale_amount * 1 AS sale_amount_times_one,
    s.sale_amount + 0 AS sale_amount_plus_zero,
    s.sale_amount / 1 AS sale_amount_divided_one,
    s.sale_date,
    DATE(s.sale_date) AS sale_date_formatted,
    YEAR(s.sale_date) AS sale_year,
    MONTH(s.sale_date) AS sale_month,
    DAY(s.sale_date) AS sale_day,
    SUM(s.sale_amount) OVER (PARTITION BY c.country) AS country_total_sales
FROM 
    customer_data c
    INNER JOIN sales_data s ON c.customer_id = s.customer_id
    LEFT JOIN temp_all_customers tc ON c.customer_id = tc.customer_id  
    LEFT JOIN temp_all_sales ts ON s.sale_id = ts.sale_id
    RIGHT JOIN temp_customer_details tcd ON c.customer_id = tcd.customer_id
    LEFT JOIN customer_data c_self1 ON c.customer_id = c_self1.customer_id
    LEFT JOIN customer_data c_self2 ON c.customer_id = c_self2.customer_id
    LEFT JOIN sales_data s_self1 ON s.sale_id = s_self1.sale_id
    LEFT JOIN sales_data s_self2 ON s.sale_id = s_self2.sale_id
GROUP BY 
    c.customer_id, c.customer_name, c.email, c.country, c.region, c.city, 
    c.registration_date, c.customer_type,
    s.sale_id, s.customer_id, s.product_id, s.product_name, s.category,
    s.sale_amount, s.sale_date, s.quantity, s.discount_percent, s.sales_rep_id,
    tc.customer_id, tc.customer_name, tc.email, tc.country, tc.region, tc.city,
    tc.registration_date, tc.customer_type,
    ts.sale_id, ts.customer_id, ts.product_id, ts.product_name, ts.category,
    ts.sale_amount, ts.sale_date, ts.quantity, ts.discount_percent, ts.sales_rep_id,
    tcd.customer_id, tcd.customer_name, tcd.email, tcd.country, tcd.region, tcd.city,
    tcd.registration_date, tcd.customer_type, tcd.duplicate_name, tcd.duplicate_email, tcd.duplicate_country
HAVING 
    SUM(s.sale_amount) > 0
ORDER BY 
    c.country, c.region, c.city, c.customer_name, s.sale_date, s.product_name,
    tc.customer_name, ts.sale_date, tcd.duplicate_name;

DROP TEMPORARY TABLE temp_all_customers;
DROP TEMPORARY TABLE temp_all_sales; 
DROP TEMPORARY TABLE temp_customer_details;
