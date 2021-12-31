/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(price) AS total_spent
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id; 

-- 2. How many days has each customer visited the restaurant?
SELECT s.customer_id, count(distinct(order_date)) 
FROM dannys_diner.sales AS s
GROUP BY s.customer_id
ORDER BY s.customer_id; 

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM (WITH table_name AS(
            SELECT s.customer_id,s.order_date,m.product_name
            FROM dannys_diner.sales as s
           	LEFT JOIN dannys_diner.menu as m ON S.product_id = M.product_id
            ORDER BY order_date
        )
        SELECT customer_id,product_name,
        RANK() OVER (
                ORDER BY order_date
            ) as rank_order
        FROM table_name
    ) as rank_product
WHERE rank_order = 1
GROUP BY customer_id, product_name
ORDER BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT  m.product_name, COUNT(s.product_id) AS total_order
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu as m ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY total_order DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
WITH most_popular_item AS
(SELECT s.customer_id, m.product_name, 
  COUNT(m.product_id) AS times_purchased,
  DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY COUNT(s.customer_id) DESC) AS rank
FROM dannys_diner.menu AS m
JOIN dannys_diner.sales AS s ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_id, product_name)
SELECT * FROM most_popular_item
WHERE rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
WITH member_sales AS 
(SELECT s.customer_id, mem.join_date, s.order_date, s.product_id,
         DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY s.order_date) AS rank
     FROM dannys_diner.sales AS s
 JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
 WHERE s.order_date >= mem.join_date)
SELECT s.customer_id, s.order_date, me.product_name 
FROM member_sales AS s
JOIN dannys_diner.menu AS me ON s.product_id = me.product_id
WHERE rank = 1
ORDER BY s.customer_id;

-- 7. Which item was purchased just before the customer became a member?
WITH prior_member_sales AS 
(SELECT s.customer_id, mem.join_date, s.order_date, s.product_id,
         DENSE_RANK() OVER(PARTITION BY s.customer_id
  ORDER BY s.order_date DESC) AS rank
     FROM dannys_diner.sales AS s
 JOIN dannys_diner.members AS mem ON s.customer_id = mem.customer_id
 WHERE s.order_date < mem.join_date)
SELECT p.customer_id, p.order_date, me.product_name 
FROM prior_member_sales AS p
JOIN dannys_diner.menu AS me ON p.product_id = me.product_id
WHERE rank = 1
ORDER BY p.customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(DISTINCT s.product_id) AS unique_menu, SUM(m.price) AS total_sales
FROM dannys_diner.sales AS s
JOIN dannys_diner.members AS mem
 ON s.customer_id = mem.customer_id
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH price_points AS
 (SELECT *, 
 CASE
  WHEN product_id = 1 THEN price * 20
  ELSE price * 10
  END AS points
 FROM dannys_diner.menu)
SELECT s.customer_id, SUM(p.points) AS total_points
FROM price_points AS p
JOIN dannys_diner.sales AS s ON p.product_id = s.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id; 

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH dates AS 
(SELECT *, 
  (join_date + INTERVAL '6 day') AS valid_date, 
  DATE_TRUNC('month', '2021-01-31'::date + INTERVAL '1 MONTH')
        - INTERVAL '1 DAY' AS last_date
 FROM dannys_diner.members AS mem)
SELECT d.customer_id, s.order_date, d.join_date, 
 d.valid_date, d.last_date, m.product_name, m.price,
 SUM(CASE
  WHEN m.product_name = 'sushi' THEN 2 * 10 * m.price
  WHEN s.order_date BETWEEN d.join_date AND d.valid_date THEN 2 * 10 * m.price
  ELSE 10 * m.price
  END) AS points
FROM dates AS d
JOIN dannys_diner.sales AS s ON d.customer_id = s.customer_id
JOIN dannys_diner.menu AS m ON s.product_id = m.product_id
WHERE s.order_date < d.last_date
GROUP BY d.customer_id, s.order_date, d.join_date, d.valid_date, d.last_date, m.product_name, m.price;

 

