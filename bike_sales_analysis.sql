-- 1. Identify top stores and their staff counts
WITH store_sales AS (
  SELECT
    st.store_id,
    st.store_name,
    COUNT(DISTINCT o.order_id) AS total_sales,
    COUNT(DISTINCT s.staff_id) AS staff_count
  FROM stores AS st
  JOIN orders AS o USING (store_id)
  JOIN staff AS s USING (staff_id)
  GROUP BY st.store_id, st.store_name
)
SELECT *
FROM store_sales
ORDER BY total_sales DESC;

-- 2. Top 5 customers by spending
WITH customer_spend AS (
  SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS total_spent
  FROM customers AS c
  JOIN orders AS o USING (customer_id)
  JOIN order_items AS oi USING (order_id)
  GROUP BY c.customer_id, full_name
)
SELECT *
FROM customer_spend
ORDER BY total_spent DESC
LIMIT 5;

-- 3. Brand sales performance ranking
SELECT
  b.brand_name,
  COUNT(DISTINCT oi.order_id) AS num_orders,
  SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS revenue
FROM brands AS b
JOIN products AS p USING (brand_id)
JOIN order_items AS oi USING (product_id)
GROUP BY b.brand_name
ORDER BY revenue DESC;

-- 4. Inventory levels below threshold
SELECT
  p.product_id,
  p.product_name,
  SUM(st.quantity) AS total_stock
FROM products AS p
JOIN stocks AS st USING (product_id)
GROUP BY p.product_id, p.product_name
HAVING SUM(st.quantity) < 10
ORDER BY total_stock ASC;

-- 5. Counting unshipped orders by brand
SELECT
  b.brand_name,
  COUNT(o.order_id) AS unshipped_order_count
FROM brands AS b
JOIN products AS p USING (brand_id)
JOIN order_items AS oi USING (product_id)
JOIN orders AS o USING (order_id)
WHERE o.shipped_date IS NULL
GROUP BY b.brand_name
ORDER BY unshipped_order_count DESC;

-- 6. Monthly revenue & cumulative totals per brand
WITH monthly_revenue AS (
  SELECT
    b.brand_name,
    DATE_TRUNC('month', o.order_date) AS month,
    SUM(oi.quantity * (oi.list_price * (1 - oi.discount))) AS monthly_rev
  FROM brands AS b
  JOIN products AS p USING (brand_id)
  JOIN order_items AS oi USING (product_id)
  JOIN orders AS o USING (order_id)
  GROUP BY b.brand_name, month
)
SELECT
  brand_name,
  month,
  monthly_rev,
  SUM(monthly_rev) OVER (PARTITION BY brand_name ORDER BY month) AS cumulative_revenue
FROM monthly_revenue
ORDER BY brand_name, month;
