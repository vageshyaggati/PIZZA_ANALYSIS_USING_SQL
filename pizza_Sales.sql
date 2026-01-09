-- 1) Total number of orders placed
SELECT COUNT(*) AS NO_OF_ORDERS
FROM dbo.pizza_orders;

-- 2) Total number of pizza type IDs
SELECT COUNT(pizza_type_id) AS TOTAL_PIZZA_TYPE_IDS
FROM dbo.pizza_types;

-- 3) Total number of pizza types
SELECT COUNT(pizza_id) AS TOTAL_PIZZA_TYPES
FROM dbo.pizzas;

-- 4) Total order quantity placed
SELECT SUM(quantity) AS TOTAL_ORDER_QUANTITY_PLACED
FROM dbo.pizza_order_details;

-- 5) First and last transaction dates
SELECT MIN(date) AS FIRST_TRANSACTION,
       MAX(date) AS LAST_TRANSACTION
FROM dbo.pizza_orders;

-- 6) Total revenue generated
SELECT ROUND(SUM(p.price * pd.quantity), 2) AS TOTAL_REVENUE
FROM dbo.pizzas p
JOIN dbo.pizza_order_details pd
  ON p.pizza_id = pd.pizza_id;

-- 7) Highest priced pizza (name + price)
SELECT TOP 1 pt.name AS NAME,
             MAX(p.price) AS HIGHEST_PRICE_PIZZA
FROM dbo.pizza_types pt
JOIN dbo.pizzas p
  ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY MAX(p.price) DESC;

-- 8) Lowest priced pizza (name + price)
SELECT TOP 1 pt.name AS NAME,
             MIN(p.price) AS LOWEST_PRICE_PIZZA
FROM dbo.pizza_types pt
JOIN dbo.pizzas p
  ON pt.pizza_type_id = p.pizza_type_id
GROUP BY pt.name
ORDER BY MIN(p.price);

-- 9) Pizza ordered quantity by size
SELECT p.size,
       SUM(po.quantity) AS ORDERED_QTY
FROM dbo.pizzas p
JOIN dbo.pizza_order_details po
  ON p.pizza_id = po.pizza_id
GROUP BY p.size
ORDER BY ORDERED_QTY DESC;

-- 10) Pizza ordered quantity by category
SELECT pt.category,
       SUM(po.quantity) AS ORDERED_QTY
FROM dbo.pizza_types pt
JOIN dbo.pizzas p
  ON p.pizza_type_id = pt.pizza_type_id
JOIN dbo.pizza_order_details po
  ON po.pizza_id = p.pizza_id
GROUP BY pt.category
ORDER BY ORDERED_QTY DESC;

-- 11) Pizza ordered quantity by pizza name
SELECT pt.name,
       SUM(po.quantity) AS TOTAL_QTY
FROM dbo.pizza_types pt
JOIN dbo.pizzas p
  ON pt.pizza_type_id = p.pizza_type_id
JOIN dbo.pizza_order_details po
  ON p.pizza_id = po.pizza_id
GROUP BY pt.name
ORDER BY TOTAL_QTY DESC;

-- 12) Top 7 pizzas by order quantity
SELECT TOP 7 pt.name,
             SUM(po.quantity) AS TOTAL_QTY
FROM dbo.pizza_types pt
JOIN dbo.pizzas p
  ON pt.pizza_type_id = p.pizza_type_id
JOIN dbo.pizza_order_details po
  ON p.pizza_id = po.pizza_id
GROUP BY pt.name
ORDER BY TOTAL_QTY DESC;

-- 13) Distribution of orders by hour of day
SELECT DATEPART(HOUR, time) AS HOUR_OF_DAY,
       COUNT(*) AS NO_OF_PIZZAS
FROM dbo.pizza_orders
GROUP BY DATEPART(HOUR, time)
ORDER BY NO_OF_PIZZAS DESC;

-- 14) Pizza order quantity by date + average per day
SELECT po.date,
       SUM(pd.quantity) AS TOTAL_PIZZAS_ORDERED,
       AVG(SUM(pd.quantity)) OVER() AS AVG_PIZZAS_PER_DAY
FROM dbo.pizza_orders po
JOIN dbo.pizza_order_details pd
  ON po.order_id = pd.order_id
GROUP BY po.date
ORDER BY po.date;

-- 16) Percentage contribution of each category to total revenue
WITH CAT_REV AS (
    SELECT pt.category,
           SUM(p.price * pd.quantity) AS TOTAL_REVENUE
    FROM dbo.pizza_types pt
    JOIN dbo.pizzas p
      ON pt.pizza_type_id = p.pizza_type_id
    JOIN dbo.pizza_order_details pd
      ON pd.pizza_id = p.pizza_id
    GROUP BY pt.category
)
SELECT category,
       TOTAL_REVENUE,
       (TOTAL_REVENUE * 100.0 / (SELECT SUM(TOTAL_REVENUE) FROM CAT_REV)) AS PERCENTAGE
FROM CAT_REV
ORDER BY PERCENTAGE DESC;

-- 17) Cumulative revenue over time
WITH DATE_REV AS (
    SELECT po.date,
           SUM(p.price * pd.quantity) AS REVENUE
    FROM dbo.pizza_order_details pd
    JOIN dbo.pizzas p
      ON pd.pizza_id = p.pizza_id
    JOIN dbo.pizza_orders po
      ON po.order_id = pd.order_id
    GROUP BY po.date
)
SELECT date,
       revenue,
       SUM(revenue) OVER (ORDER BY date) AS CUMULATIVE_REVENUE
FROM DATE_REV;

-- 18) Top 3 pizzas by revenue per category
WITH PizzaRevenue AS (
    SELECT pt.category,
           pt.name AS PIZZA_NAME,
           SUM(pd.quantity * p.price) AS REVENUE,
           SUM(pd.quantity) AS ORDER_QTY,
           RANK() OVER (PARTITION BY pt.category ORDER BY SUM(pd.quantity * p.price) DESC) AS REVENUE_RANK
    FROM dbo.pizza_types pt
    JOIN dbo.pizzas p
      ON pt.pizza_type_id = p.pizza_type_id
    JOIN dbo.pizza_order_details pd
      ON pd.pizza_id = p.pizza_id
    GROUP BY pt.category, pt.name
)
SELECT category, PIZZA_NAME, REVENUE, ORDER_QTY, REVENUE_RANK
FROM PizzaRevenue
WHERE REVENUE_RANK <= 3
ORDER BY category, REVENUE_RANK;