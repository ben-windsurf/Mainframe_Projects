
CREATE TEMPORARY TABLE temp_all_customers AS
SELECT * FROM customer_data;

CREATE TEMPORARY TABLE temp_all_sales AS
SELECT * FROM sales_data;

CREATE TEMPORARY TABLE temp_customer_backup AS
SELECT customer_id, customer_name, country, email, phone, address, city, state, registration_date, customer_type, credit_limit, preferred_contact_method FROM customer_data;

SELECT DISTINCT 
    c1.country,
    c1.customer_id,
    c1.customer_name,
    c1.email,
    c1.phone,
    c1.address,
    c1.city,
    c1.state,
    c1.registration_date,
    c1.customer_type,
    c1.credit_limit,
    c1.preferred_contact_method,
    c2.customer_name AS duplicate_customer_name,
    c3.email AS duplicate_email,
    s1.sale_id,
    s1.customer_id AS sales_customer_id,
    s1.product_id,
    s1.product_name,
    s1.category,
    s1.sale_date,
    s1.quantity,
    s1.unit_price,
    s1.total_amount,
    s1.sales_rep_id,
    s1.sales_rep_name,
    s1.commission_rate,
    s1.discount_applied,
    s2.product_name AS duplicate_product_name,
    s3.sale_date AS duplicate_sale_date,
    s4.total_amount AS duplicate_total_amount,
    temp_c.customer_type AS temp_customer_type,
    temp_s.commission_rate AS temp_commission_rate,
    temp_backup.country AS backup_country,
    SUM(s1.total_amount) as total_sales,
    COUNT(*) as transaction_count,
    AVG(s1.total_amount) as avg_sale_amount,
    MAX(s1.total_amount) as max_sale_amount,
    MIN(s1.total_amount) as min_sale_amount
FROM customer_data c1
CROSS JOIN customer_data c2  -- Unnecessary cross join creating cartesian product
LEFT JOIN customer_data c3 ON c1.customer_id = c3.customer_id  -- Redundant join to same table
INNER JOIN sales_data s1 ON c1.customer_id = s1.customer_id
LEFT JOIN sales_data s2 ON s1.sale_id = s2.sale_id  -- Redundant self-join
RIGHT JOIN sales_data s3 ON s2.customer_id = s3.customer_id  -- Another redundant join
FULL OUTER JOIN sales_data s4 ON s3.sale_id = s4.sale_id  -- Yet another redundant join
JOIN temp_all_customers temp_c ON c1.customer_id = temp_c.customer_id  -- Unnecessary temp table join
JOIN temp_all_sales temp_s ON s1.sale_id = temp_s.sale_id  -- Another unnecessary temp table join
LEFT JOIN temp_customer_backup temp_backup ON c1.customer_id = temp_backup.customer_id  -- Third unnecessary temp table join
WHERE 1=1  -- Meaningless WHERE clause that doesn't filter anything
    AND c1.customer_id IS NOT NULL  -- Redundant condition
    AND s1.sale_id IS NOT NULL  -- Another redundant condition
    AND c1.country <> ''  -- Inefficient way to check for non-empty country
GROUP BY c1.country, c1.customer_id, c1.customer_name, c1.email, c1.phone, c1.address, c1.city, c1.state, 
         c1.registration_date, c1.customer_type, c1.credit_limit, c1.preferred_contact_method,
         c2.customer_name, c3.email, s1.sale_id, s1.customer_id, s1.product_id, s1.product_name, 
         s1.category, s1.sale_date, s1.quantity, s1.unit_price, s1.total_amount, s1.sales_rep_id, 
         s1.sales_rep_name, s1.commission_rate, s1.discount_applied, s2.product_name, s3.sale_date, 
         s4.total_amount, temp_c.customer_type, temp_s.commission_rate, temp_backup.country
HAVING SUM(s1.total_amount) >= 0  -- Meaningless HAVING clause since amounts can't be negative
    AND COUNT(*) > 0  -- Another meaningless HAVING condition
ORDER BY c1.country ASC, total_sales DESC, c1.customer_name ASC, s1.sale_date DESC, s1.product_name ASC;

SELECT DISTINCT
    temp_backup.country,
    SUM(temp_s.total_amount) as country_total_from_temp_tables
FROM temp_customer_backup temp_backup
JOIN temp_all_sales temp_s ON temp_backup.customer_id = temp_s.customer_id
WHERE temp_backup.country IS NOT NULL
GROUP BY temp_backup.country
ORDER BY country_total_from_temp_tables DESC;

DROP TEMPORARY TABLE temp_all_customers;
DROP TEMPORARY TABLE temp_all_sales;
DROP TEMPORARY TABLE temp_customer_backup;
