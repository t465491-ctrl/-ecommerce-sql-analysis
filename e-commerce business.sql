create database e_commerce;
use e_commerce;
-- Customers
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_name VARCHAR(80) NOT NULL,
    email VARCHAR(120) UNIQUE,
    city VARCHAR(60),
    created_at DATE NOT NULL
);

-- Categories
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(60) UNIQUE NOT NULL
);

-- Products
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    product_name VARCHAR(120) NOT NULL,
    category_id INT NOT NULL,
    price DECIMAL(10 , 2 ) NOT NULL CHECK (price >= 0),
    CONSTRAINT fk_prod_cat FOREIGN KEY (category_id)
        REFERENCES categories (category_id)
);

-- Orders
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    status ENUM('placed', 'shipped', 'delivered', 'cancelled', 'returned') NOT NULL DEFAULT 'placed',
    CONSTRAINT fk_ord_cust FOREIGN KEY (customer_id)
        REFERENCES customers (customer_id)
);

-- Order Items
CREATE TABLE order_items (
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10 , 2 ) NOT NULL CHECK (unit_price >= 0),
    PRIMARY KEY (order_id , product_id),
    CONSTRAINT fk_oi_o FOREIGN KEY (order_id)
        REFERENCES orders (order_id),
    CONSTRAINT fk_oi_p FOREIGN KEY (product_id)
        REFERENCES products (product_id)
);

-- Payments
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    paid_amount DECIMAL(10 , 2 ) NOT NULL CHECK (paid_amount >= 0),
    payment_method ENUM('card', 'upi', 'cod', 'wallet') NOT NULL,
    paid_at DATETIME NOT NULL,
    CONSTRAINT fk_pay_o FOREIGN KEY (order_id)
        REFERENCES orders (order_id)
);

-- Helpful indexes
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);
CREATE INDEX idx_products_cat ON products(category_id);

INSERT INTO customers (customer_name, email, city, created_at) VALUES
('Amit Sharma','amit@example.com','Delhi','2024-01-05'),
('Priya Verma','priya@example.com','Mumbai','2024-01-11'),
('Rahul Singh','rahul@example.com','Bangalore','2024-02-02'),
('Neha Gupta','neha@example.com','Chennai','2024-02-15'),
('Ravi Kumar','ravi@example.com','Kolkata','2024-03-01');

INSERT INTO categories (category_name) VALUES
('Electronics'),('Fashion'),('Home'),('Books');

INSERT INTO products (product_name, category_id, price) VALUES
('Laptop Pro 14', 1, 85000.00),
('Smartphone X', 1, 48000.00),
('Wireless Headphones', 1, 3500.00),
('Running Shoes', 2, 4200.00),
('Casual T-shirt', 2, 700.00),
('Air Fryer', 3, 6500.00),
('Cookware Set', 3, 3200.00),
('Novel: Quiet River', 4, 499.00);

-- Orders (2024 spread)
INSERT INTO orders (customer_id, order_date, status) VALUES
(1,'2024-01-15','delivered'),
(2,'2024-02-10','delivered'),
(3,'2024-03-05','delivered'),
(1,'2024-03-20','delivered'),
(4,'2024-04-01','shipped'),
(5,'2024-04-10','cancelled'),
(2,'2024-05-12','returned'),
(3,'2024-06-18','delivered'),
(5,'2024-07-02','delivered'),
(1,'2024-08-21','delivered');

-- Order Items (use product price as unit_price at time of order)
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1,1,1,85000.00),                 -- Laptop Pro 14
(2,2,1,48000.00),
(2,3,1,3500.00),
(3,4,1,4200.00),
(4,3,2,3500.00),
(5,2,1,48000.00),
(6,5,3,700.00),
(7,2,1,48000.00),
(8,6,1,6500.00), 
(8,7,1,3200.00),
(9,8,2,499.00),
(10,2,1,48000.00), 
(10,3,1,3500.00);

-- Payments (simulate full/partial + returned/cancelled edge cases)
INSERT INTO payments (order_id, paid_amount, payment_method, paid_at) VALUES
(1,85000.00,'card','2024-01-15 10:05:00'),
(2,51500.00,'upi','2024-02-10 14:11:00'),
(3,4200.00,'wallet','2024-03-05 09:50:00'),
(4,7000.00,'cod','2024-03-20 16:40:00'),
(5,0.00,'card','2024-04-01 11:22:00'),       -- not captured yet (shipped)
(6,0.00,'upi','2024-04-10 10:00:00'),        -- cancelled
(7,0.00,'card','2024-05-12 12:05:00'),       -- returned (refund issued externally)
(8,9700.00,'upi','2024-06-18 18:15:00'),
(9,998.00,'wallet','2024-07-02 08:30:00'),
(10,51500.00,'card','2024-08-21 19:00:00');

SELECT 
    c.customer_name, c.city
FROM
    customers c
        LEFT JOIN
    orders o ON o.customer_id = c.customer_id
WHERE
    status = 'delivered';

-- For each category, total quantity sold.
SELECT 
    category_name, SUM(quantity) AS quantity_sold
FROM
    categories c
        JOIN
    products p ON c.category_id = p.category_id
        JOIN
    order_items o ON o.product_id = p.product_id
GROUP BY category_name;

-- For each customer, total orders placed and total delivered orders.
with order_place as(
select c.customer_id,c.customer_name ,count(*) total_order_placed
from customers c
join orders o
on c.customer_id = o.customer_id
group by customer_name,c.customer_id ),

status_delivered as (
select c.customer_id, coalesce(count(status),0) as delivered
from customers c 
join orders o
on c.customer_id = o.customer_id 
where status = 'delivered'
group by c.customer_id)

select op.customer_name , op.total_order_placed, coalesce(sd.delivered,0) as delivered 
from order_place op
left join status_delivered sd
on op.customer_id = sd.customer_id  ;


-- For 2024-Q2 (Apr–Jun), monthly GMV = sum of quantity * unit_price from delivered only.

SELECT 
    COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS gmv
FROM
    order_items oi
        JOIN
    orders o ON oi.order_id = o.order_id
WHERE
    o.status = 'delivered'
        AND o.order_date >= '2024-04-01'
        AND o.order_date < '2024-07-01';


-- Compute each order’s order_total from order_items and compare vs payments.paid_amount (flag underpaid, exact, overpaid).

WITH order_totals AS (
  SELECT oi.order_id,
         SUM(oi.quantity * oi.unit_price) AS order_total
  FROM order_items oi
  GROUP BY oi.order_id
),
payments_agg AS (
  SELECT p.order_id,
         SUM(p.paid_amount) AS paid_amount
  FROM payments p
  GROUP BY p.order_id
)
SELECT  o.order_id,
        ot.order_total,
        COALESCE(pa.paid_amount, 0) AS paid_amount,
        o.status,
        CASE
          WHEN o.status IN ('cancelled','returned') THEN o.status
          WHEN COALESCE(pa.paid_amount,0) = 0 THEN 'unpaid'
          WHEN COALESCE(pa.paid_amount,0) + 0.01 < ot.order_total THEN 'underpaid'
          WHEN COALESCE(pa.paid_amount,0) - 0.01 > ot.order_total THEN 'overpaid'
          ELSE 'exact'
        END AS payment_state
FROM orders o
JOIN order_totals ot ON ot.order_id = o.order_id
LEFT JOIN payments_agg pa ON pa.order_id = o.order_id
ORDER BY o.order_id;


-- Find the top 3 products by revenue (delivered only).

select product_name,sum(quantity*unit_price) as revenue 
from products p
join order_items oi
on p.product_id = oi.product_id
join orders o
on o.order_id = oi.order_id
where status = "delivered"
group by  product_name
order by revenue desc limit 3;

-- For each city, compute AOV (average order value) on delivered orders.


select city, round(avg(quantity*unit_price),2) as avg_order_value
from order_items oi
join orders o
on oi.order_id = o.order_id
join customers c 
on c.customer_id = o.customer_id
group by city ;

-- Identify customers with no orders (should be none here after seeds—but your query should work generally)
select c.customer_id,customer_name ,city 
from customers c
left join orders o
on c.customer_id = o.customer_id
where order_id  is null;

--  Return/cancel analysis: total GMV lost from orders with status in ('cancelled','returned').


SELECT COALESCE(SUM(oi.unit_price * oi.quantity), 0) AS gmv_lost
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE status in ('cancelled','returned')
;


--  Payment method mix (% share of paid_amount by method for delivered orders).

with delivered_payment as 
(select payment_method , sum(paid_amount) as paid_method
from payments p 
join orders o
on o.order_id = p.order_id
where status = "delivered"
group by payment_method),

tot as(
select sum(paid_amount) as total_paid
from payments)

select payment_method ,
round(100*dp.paid_method/nullif(total_paid,0),2) as contribution
from delivered_payment dp
join  tot ;


-- Build a CTE order_totals(order_id, order_total) then rank customers by lifetime revenue (delivered only). Show top 5.

with order_total as(
select order_id ,sum(quantity*unit_price) as total_amount
from order_items
group by order_id
),
order_delivered as (
select order_id,customer_name 
from customers c
left join orders o
on c.customer_id = o.customer_id 
where status = "delivered")

select customer_name ,total_amount,
dense_rank() over(order by total_amount desc) as ranking 
from order_delivered od
left join order_total ot
on od.order_id = ot.order_id
limit 5;

-- Compute month-over-month GMV (delivered) and add a column for MoM% change.

WITH monthly_gmv AS (
  SELECT DATE_FORMAT(o.order_date, '%Y-%m') AS date,
         SUM(oi.quantity * oi.unit_price)   AS sales 
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.status = 'delivered'
  GROUP BY DATE_FORMAT(o.order_date, '%Y-%m')
)
SELECT date,
       sales,
       ROUND(
         (sales - LAG(sales) OVER (ORDER BY date))
         / NULLIF(LAG(sales) OVER (ORDER BY date), 0) * 100, 2
       ) AS mom_pct
FROM monthly_gmv
ORDER BY date;


-- For each product, compute a running total of delivered quantity over time (by order_date).

WITH product_daily AS (
  SELECT p.product_id,
         p.product_name,
         o.order_date AS order_date,  -- drop ::date if MySQL
         SUM(oi.quantity) AS qty
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  JOIN orders o       ON o.order_id     = oi.order_id
  WHERE o.status = 'delivered'
  GROUP BY p.product_id, p.product_name, o.order_date
)
SELECT product_name,
       order_date,
       qty as quantity ,
       SUM(qty) OVER (
         PARTITION BY product_id
         ORDER BY order_date
         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS running_quantity_sold
FROM product_daily
ORDER BY product_name, order_date;


