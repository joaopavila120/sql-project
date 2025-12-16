DROP DATABASE IF EXISTS coffee_ecommerce;
CREATE DATABASE coffee_ecommerce CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE coffee_ecommerce;

/* =============================================================================
   SECTION 1: DATABASE SCHEMA DEFINITION
   ============================================================================= */

/* -----------------------------------------------------------------------------
   TABLE: users
   DESCRIPTION: Stores user account information including login credentials and profile data.
   COLUMNS:
     user_id: Unique identifier for the user (BIGINT for scalability)
     email: User email address, used for login
     password_hash: Hashed password for security
     full_name: Full name of the user
     phone: Contact phone number
     created_at: Timestamp when the user was created
   ----------------------------------------------------------------------------- */
CREATE TABLE users (
  user_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  email          VARCHAR(150) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  full_name      VARCHAR(100) NOT NULL,
  phone          VARCHAR(20),
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: countries
   DESCRIPTION: Lookup table for countries.
   COLUMNS:
     country_code: ISO 3166-1 alpha-2 country code (e.g., PT, US)
     name: Full name of the country
   ----------------------------------------------------------------------------- */
CREATE TABLE countries (
  country_code   CHAR(2) PRIMARY KEY,
  name           VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: addresses
   DESCRIPTION: Stores user shipping and billing addresses.
   COLUMNS:
     address_id: Unique identifier for the address
     user_id: Foreign key linking to the user
     street: Street address including number
     city: City name
     postal_code: Postal or ZIP code
     country_code: Foreign key linking to the country
     is_default: Flag indicating if this is the default address
   ----------------------------------------------------------------------------- */
CREATE TABLE addresses (
  address_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id        BIGINT NOT NULL,
  street         VARCHAR(150) NOT NULL,
  city           VARCHAR(100) NOT NULL,
  postal_code    VARCHAR(20) NOT NULL,
  country_code   CHAR(2) NOT NULL DEFAULT 'PT',
  is_default     BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  FOREIGN KEY (country_code) REFERENCES countries(country_code)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: categories
   DESCRIPTION: Product categories for organization (e.g., Coffee, Equipment).
   COLUMNS:
     category_id: Unique identifier for the category
     name: Name of the category
     description: Short description of the category
   ----------------------------------------------------------------------------- */
CREATE TABLE categories (
  category_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  name           VARCHAR(100) NOT NULL UNIQUE,
  description    VARCHAR(255)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: brands
   DESCRIPTION: Brands or manufacturers of products.
   COLUMNS:
     brand_id: Unique identifier for the brand
     name: Brand name
     country_code: Foreign key linking to the country of origin
   ----------------------------------------------------------------------------- */
CREATE TABLE brands (
  brand_id       BIGINT PRIMARY KEY AUTO_INCREMENT,
  name           VARCHAR(100) NOT NULL UNIQUE,
  country_code   CHAR(2),
  FOREIGN KEY (country_code) REFERENCES countries(country_code)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: products
   DESCRIPTION: Main product catalog.
   COLUMNS:
     product_id: Unique identifier for the product
     category_id: Foreign key linking to the category
     brand_id: Foreign key linking to the brand
     name: Name of the product
     description: Detailed description of the product
     price: Price of the product in EUR (DECIMAL for financial precision)
     stock_quantity: Current stock level
     is_active: Flag indicating if the product is available for sale
     created_at: Timestamp when the product was added
   ----------------------------------------------------------------------------- */
CREATE TABLE products (
  product_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  category_id    BIGINT NOT NULL,
  brand_id       BIGINT,
  name           VARCHAR(150) NOT NULL,
  description    TEXT,
  price          DECIMAL(10,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id)    REFERENCES categories(category_id),
  FOREIGN KEY (brand_id)       REFERENCES brands(brand_id)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: product_attributes
   DESCRIPTION: Stores specific attributes for products (e.g., Roast, Voltage).
   COLUMNS:
     attribute_id: Unique identifier for the attribute
     product_id: Foreign key linking to the product
     attribute_name: Name of the attribute (e.g., 'Roast Level')
     attribute_value: Value of the attribute (e.g., 'Dark')
   ----------------------------------------------------------------------------- */
CREATE TABLE product_attributes (
  attribute_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  product_id     BIGINT NOT NULL,
  attribute_name VARCHAR(50) NOT NULL,
  attribute_value VARCHAR(100) NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: coupons
   DESCRIPTION: Discount coupons for promotions.
   COLUMNS:
     coupon_id: Unique identifier for the coupon
     code: Discount code entered by the user
     discount_val: Value of the discount
     discount_type: Type of discount (fixed amount or percentage)
     valid_until: Expiration date of the coupon
     is_active: Flag indicating if the coupon is currently valid
   ----------------------------------------------------------------------------- */
CREATE TABLE coupons (
  coupon_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  code           VARCHAR(50) NOT NULL UNIQUE,
  discount_val   DECIMAL(10,2) NOT NULL,
  discount_type  ENUM('FIXED','PERCENTAGE') NOT NULL,
  valid_until    DATETIME,
  is_active      BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: orders
   DESCRIPTION: Stores customer orders and their status.
   COLUMNS:
     order_id: Unique identifier for the order
     user_id: Foreign key linking to the user who placed the order
     address_id: Foreign key linking to the shipping address
     coupon_id: Foreign key linking to the applied coupon (optional)
     status: Current status of the order
     payment_method: Method used for payment
     payment_ref: External reference ID from the payment provider
     carrier_name: Name of the shipping carrier
     tracking_code: Tracking code for the shipment
     created_at: Timestamp when the order was placed
   ----------------------------------------------------------------------------- */
CREATE TABLE orders (
  order_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id          BIGINT NOT NULL,
  address_id       BIGINT NOT NULL,
  coupon_id        BIGINT,
  status           ENUM('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  payment_method   ENUM('CREDIT_CARD','PAYPAL','MBWAY') NOT NULL,
  payment_ref      VARCHAR(100),
  carrier_name     VARCHAR(100),
  tracking_code    VARCHAR(100),
  created_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)    REFERENCES users(user_id),
  FOREIGN KEY (address_id) REFERENCES addresses(address_id),
  FOREIGN KEY (coupon_id)  REFERENCES coupons(coupon_id)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: order_items
   DESCRIPTION: Individual items within an order.
   COLUMNS:
     order_item_id: Unique identifier for the order item
     order_id: Foreign key linking to the order
     product_id: Foreign key linking to the product
     quantity: Quantity of the product ordered
     unit_price: Price per unit at the time of purchase
   ----------------------------------------------------------------------------- */
CREATE TABLE order_items (
  order_item_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id       BIGINT NOT NULL,
  product_id     BIGINT NOT NULL,
  quantity       INT NOT NULL,
  unit_price     DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: reviews
   DESCRIPTION: Product reviews submitted by users.
   COLUMNS:
     review_id: Unique identifier for the review
     product_id: Foreign key linking to the product
     user_id: Foreign key linking to the user
     rating: Rating given by the user (1-5)
     comment: Textual comment for the review
     created_at: Timestamp when the review was created
   ----------------------------------------------------------------------------- */
CREATE TABLE reviews (
  review_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  product_id     BIGINT NOT NULL,
  user_id        BIGINT NOT NULL,
  rating         TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment        TEXT,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  FOREIGN KEY (user_id)    REFERENCES users(user_id)
) ENGINE=InnoDB;

/* -----------------------------------------------------------------------------
   TABLE: transaction_logs
   DESCRIPTION: Audit trail for critical system transactions.
   COLUMNS:
     log_id: Unique identifier for the log entry
     order_id: Foreign key linking to the related order (optional)
     user_id: Foreign key linking to the user who performed the action (optional)
     action_type: Type of action (e.g., PAYMENT_SUCCESS, ORDER_CANCELLED)
     description: Detailed description of the event
     log_date: Timestamp when the event occurred
   ----------------------------------------------------------------------------- */
CREATE TABLE transaction_logs (
  log_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id       BIGINT,
  user_id        BIGINT,
  action_type    VARCHAR(50) NOT NULL,
  description    TEXT,
  log_date       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  FOREIGN KEY (user_id)  REFERENCES users(user_id)
) ENGINE=InnoDB;


/* =============================================================================
   SECTION 1.1: TRIGGERS
   ============================================================================= */

-- Trigger 1: Log when a new order is placed
DELIMITER $$

-- Trigger 1: Log when a new order is placed
CREATE TRIGGER trg_log_order_placement
AFTER INSERT ON orders
FOR EACH ROW
BEGIN
  INSERT INTO transaction_logs (order_id, user_id, action_type, description, log_date)
  VALUES (NEW.order_id, NEW.user_id, 'ORDER_PLACED',
          CONCAT('Order placed with status: ', NEW.status),
          NEW.created_at);
END$$
SELECT * FROM transaction_logs;
-- Trigger 2: Log when an order is updated
CREATE TRIGGER trg_log_order_update
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
  IF OLD.status <> NEW.status THEN
    INSERT INTO transaction_logs (order_id, user_id, action_type, description, log_date)
    VALUES (NEW.order_id, NEW.user_id, 'ORDER_UPDATED',
            CONCAT('Status changed from ', OLD.status, ' to ', NEW.status),
            NOW());
  END IF;
 -- 2) Update product stock ONLY when the order becomes PAID for the first time
  IF OLD.status <> 'PAID' AND NEW.status = 'PAID' THEN
    UPDATE products p
    JOIN order_items oi ON oi.product_id = p.product_id
    SET p.stock_quantity = p.stock_quantity - oi.quantity
    WHERE oi.order_id = NEW.order_id;
  END IF;
END$$

DELIMITER ;

/* =============================================================================
   SECTION 2: DUMMY DATA GENERATION
   ============================================================================= */

-- 1. Countries
INSERT INTO countries (country_code, name) VALUES
('PT', 'Portugal'),
('US', 'United States'),
('BR', 'Brazil'),
('ES', 'Spain'),
('FR', 'France'),
('JP', 'Japan');

-- 2. Users (5 users)
INSERT INTO users (email, password_hash, full_name, phone, created_at) VALUES
('john.doe@example.com', 'hash123', 'John Doe', '+351912345678', DATE_SUB(NOW(), INTERVAL 2 YEAR)),
('jane.smith@example.com', 'hash456', 'Jane Smith', '+15550199', DATE_SUB(NOW(), INTERVAL 23 MONTH)),
('alice.jones@example.com', 'hash789', 'Alice Jones', '+351933333333', DATE_SUB(NOW(), INTERVAL 20 MONTH)),
('bob.brown@example.com', 'hashabc', 'Bob Brown', '+351966666666', DATE_SUB(NOW(), INTERVAL 18 MONTH)),
('charlie.black@example.com', 'hashxyz', 'Charlie Black', '+33123456789', DATE_SUB(NOW(), INTERVAL 1 YEAR));

-- 3. Addresses
INSERT INTO addresses (user_id, street, city, postal_code, country_code, is_default) VALUES
(1, 'Rua da Liberdade 123', 'Lisbon', '1000-001', 'PT', TRUE),
(2, '123 Main St', 'New York', '10001', 'US', TRUE),
(3, 'Avenida dos Aliados 45', 'Porto', '4000-001', 'PT', TRUE),
(4, 'Rua de Santa Catarina 88', 'Porto', '4000-002', 'PT', TRUE),
(5, '10 Rue de Rivoli', 'Paris', '75001', 'FR', TRUE);

-- 4. Categories
INSERT INTO categories (name, description) VALUES
('Coffee Beans', 'Whole bean and ground coffee from around the world'),
('Equipment', 'Espresso machines, grinders, and brewing gear'),
('Accessories', 'Filters, cups, and maintenance tools');

-- 5. Brands
INSERT INTO brands (name, country_code) VALUES
('Delta', 'PT'),
('Hario', 'JP'),
('Sage', 'US'),
('Oatlys', 'US');

-- 6. Products
INSERT INTO products (category_id, brand_id, name, description, price, stock_quantity) VALUES
(1, 1, 'Delta Gold Blend', 'Smooth and balanced blend.', 15.50, 100),
(1, 1, 'Delta Platinum Roast', 'Intense dark roast.', 18.00, 80),
(2, 2, 'Hario V60 Dripper', 'Ceramic coffee dripper size 02.', 25.00, 50),
(2, 3, 'Sage Barista Express', 'All-in-one espresso machine.', 599.99, 10),
(3, 2, 'Hario Paper Filters', 'Pack of 100 filters.', 8.50, 200);

-- 7. Product Attributes
INSERT INTO product_attributes (product_id, attribute_name, attribute_value) VALUES
(1, 'Roast', 'Medium'), (1, 'Origin', 'Blend'),
(2, 'Roast', 'Dark'), (2, 'Origin', 'Blend'),
(3, 'Material', 'Ceramic'), (3, 'Color', 'White'),
(4, 'Voltage', '220V'), (4, 'Color', 'Stainless Steel'),
(5, 'Size', '02'), (5, 'Count', '100');

-- 8. Coupons
INSERT INTO coupons (code, discount_val, discount_type, valid_until) VALUES
('WELCOME10', 10.00, 'PERCENTAGE', DATE_ADD(NOW(), INTERVAL 1 YEAR)),
('SUMMER5', 5.00, 'FIXED', DATE_ADD(NOW(), INTERVAL 6 MONTH));

-- 9. Orders (30 rows spread over 2 years)
-- We will generate 30 orders.
-- IDs 1-10: Year 1
-- IDs 11-20: Year 2 (First Half)
-- IDs 21-30: Year 2 (Recent)

INSERT INTO orders (user_id, address_id, coupon_id, status, payment_method, created_at) VALUES
-- Year 1 (Oldest)
(1, 1, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 700 DAY)),
(2, 2, 1, 'DELIVERED', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 680 DAY)),
(3, 3, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 650 DAY)),
(1, 1, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 620 DAY)),
(4, 4, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 600 DAY)),
(5, 5, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 580 DAY)),
(2, 2, NULL, 'DELIVERED', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 550 DAY)),
(3, 3, 1, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 520 DAY)),
(1, 1, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 500 DAY)),
(4, 4, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 480 DAY)),

-- Year 2 (Mid)
(5, 5, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 360 DAY)),
(1, 1, 2, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 330 DAY)),
(2, 2, NULL, 'DELIVERED', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 300 DAY)),
(3, 3, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 270 DAY)),
(4, 4, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 240 DAY)),
(5, 5, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 210 DAY)),
(1, 1, NULL, 'DELIVERED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 180 DAY)),
(2, 2, NULL, 'DELIVERED', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 150 DAY)),
(3, 3, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 120 DAY)),
(4, 4, NULL, 'DELIVERED', 'MBWAY', DATE_SUB(NOW(), INTERVAL 90 DAY)),

-- Recent (Last 3 months)
(5, 5, NULL, 'SHIPPED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 60 DAY)),
(1, 1, NULL, 'SHIPPED', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 45 DAY)),
(2, 2, NULL, 'SHIPPED', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 30 DAY)),
(3, 3, NULL, 'PAID', 'MBWAY', DATE_SUB(NOW(), INTERVAL 15 DAY)),
(4, 4, NULL, 'PAID', 'MBWAY', DATE_SUB(NOW(), INTERVAL 10 DAY)),
(5, 5, NULL, 'PAID', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 5 DAY)),
(1, 1, NULL, 'PENDING', 'CREDIT_CARD', DATE_SUB(NOW(), INTERVAL 3 DAY)),
(2, 2, NULL, 'PENDING', 'PAYPAL', DATE_SUB(NOW(), INTERVAL 2 DAY)),
(3, 3, NULL, 'PENDING', 'MBWAY', DATE_SUB(NOW(), INTERVAL 1 DAY)),
(4, 4, NULL, 'CANCELLED', 'MBWAY', NOW());

-- 10. Order Items (Linking products to orders)
-- Random distribution of items
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
(1, 1, 2, 15.50), 
(1, 5, 1, 8.50),
(2, 3, 1, 25.00),
(3, 2, 3, 18.00),
(4, 1, 1, 15.50),
(5, 5, 5, 8.50),
(6, 4, 1, 599.99),
(7, 2, 2, 18.00),
(8, 3, 1, 25.00), (8, 5, 1, 8.50),
(9, 1, 1, 15.50),
(10, 2, 1, 18.00),
(11, 1, 2, 15.50),
(12, 3, 1, 25.00),
(13, 2, 1, 18.00),
(14, 5, 2, 8.50),
(15, 1, 1, 15.50),
(16, 4, 1, 599.99),
(17, 2, 2, 18.00),
(18, 3, 1, 25.00),
(19, 1, 3, 15.50),
(20, 5, 1, 8.50),
(21, 2, 1, 18.00),
(22, 1, 1, 15.50),
(23, 3, 1, 25.00),
(24, 2, 2, 18.00),
(25, 5, 3, 8.50),
(26, 1, 1, 15.50),
(27, 2, 1, 18.00),
(28, 3, 1, 25.00),
(29, 1, 2, 15.50),
(30, 5, 1, 8.50);

-- 11. Reviews
INSERT INTO reviews (product_id, user_id, rating, comment, created_at) VALUES
(1, 1, 5, 'Great coffee!', DATE_SUB(NOW(), INTERVAL 600 DAY)),
(4, 5, 5, 'Best machine ever.', DATE_SUB(NOW(), INTERVAL 500 DAY)),
(3, 2, 4, 'Good but fragile.', DATE_SUB(NOW(), INTERVAL 400 DAY));

/* =============================================================================
   SECTION 3: INVOICE VIEWS
   ============================================================================= */

-- View 1: Invoice header and totals (one row per order)
CREATE OR REPLACE VIEW v_invoice_header AS
SELECT
  o.order_id AS invoice_number,
  o.created_at AS invoice_date,
  -- Billed to customer
  u.full_name AS customer_name,
  u.email AS customer_email,
  a.street AS customer_street,
  a.city AS customer_city,
  a.postal_code AS customer_postal_code,
  c.name AS customer_country,
  -- Company information
  'SQLatte Coffee E-Commerce' AS company_name,
  'Rua Augusta, 123' AS company_street,
  'Lisbon' AS company_city,
  '1000-001' AS company_postal_code,
  'Portugal' AS company_country,
  'info@sqlatte.com' AS company_email,
  '+351 912 000 000' AS company_phone,
  -- Totals
  ot.subtotal AS subtotal,
  COALESCE(
    CASE
        WHEN cp.discount_type = 'FIXED' THEN cp.discount_val
        WHEN cp.discount_type = 'PERCENTAGE' THEN ot.subtotal * (cp.discount_val / 100)
        ELSE 0
    END,
    0
) AS discount_amount,
0 AS tax_rate,
0 AS tax_amount,
(ot.subtotal
- COALESCE(
	CASE
		WHEN cp.discount_type = 'FIXED' THEN cp.discount_val
		WHEN cp.discount_type = 'PERCENTAGE' THEN ot.subtotal * (cp.discount_val / 100)
		ELSE 0
	END,
	0
)
) AS total
FROM orders o
JOIN users u ON u.user_id = o.user_id
JOIN addresses a ON a.address_id = o.address_id
JOIN countries c ON c.country_code = a.country_code
LEFT JOIN coupons cp ON cp.coupon_id = o.coupon_id
JOIN (
    -- Order totals 
    SELECT
      order_id,
      SUM(quantity * unit_price) AS subtotal
    FROM order_items
    GROUP BY order_id
) ot ON ot.order_id = o.order_id;

-- View 2: Invoice detail lines 
CREATE OR REPLACE VIEW v_invoice_lines AS
SELECT
  o.order_id AS invoice_number,
  p.name AS description,
  oi.unit_price AS unit_cost,
  oi.quantity AS quantity,
  (oi.unit_price * oi.quantity) AS amount
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id;

/* =============================================================================
   BUSINESS QUESTIONS
   ============================================================================= */
   
-- 1. High-Value Customer and Product Performance
-- Which are our top 3 selling products by total revenue, and which customers have
-- placed the most orders that included at least one of these top-selling products?

WITH TopSellingProducts AS (
    -- 1. Identify the top 3 products by total revenue 
    SELECT 
		oi.product_id, 
        p.name AS product_name, 
        SUM(oi.quantity * oi.unit_price) AS product_revenue_total
    FROM order_items oi
    JOIN products p ON p.product_id = oi.product_id
    GROUP BY oi.product_id, p.name
    ORDER BY product_revenue_total DESC
    LIMIT 3
)
-- 2. Aggregate customer order counts for these specific products
SELECT 
	u.user_id, 
    u.full_name AS customer_name, 
	COUNT(DISTINCT o.order_id) AS orders_with_top_product_count,
	GROUP_CONCAT(DISTINCT tsp.product_name ORDER BY tsp.product_name SEPARATOR ', ') 
    AS purchased_top_products
FROM orders o
JOIN users u ON u.user_id = o.user_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN TopSellingProducts tsp ON tsp.product_id = oi.product_id
-- Only successfully paid/shipped/delivered orders 
WHERE o.status IN ('PAID', 'SHIPPED', 'DELIVERED')
GROUP BY u.user_id, u.full_name
ORDER BY orders_with_top_product_count DESC, u.user_id
LIMIT 5; 

-- 2. Coupon Effectiveness by Order Status
-- What is the usage rate of each coupon code, and how does the use of a coupon 
-- (compared to no coupon) impact the order's final status
-- (specifically looking at the rate of being CANCELLED versus DELIVERED)?

-- Grouping by coupon code (or 'NO_COUPON') and order status
SELECT 
	COALESCE(cp.code, 'NO_COUPON') AS coupon_code, 
    o.status AS order_status, 
	COUNT(o.order_id) AS number_of_orders,
	-- Calculate the total revenue associated with this group for context
    SUM(vh.total) AS total_revenue_contribution
FROM orders o
LEFT JOIN coupons cp ON cp.coupon_id = o.coupon_id
-- Join with the Invoice Header View to easily get the final calculated total
JOIN v_invoice_header vh ON vh.invoice_number = o.order_id 
-- Focus on the statuses most relevant to success (DELIVERED) and failure (CANCELLED)
WHERE o.status IN ('DELIVERED', 'CANCELLED')
GROUP BY coupon_code, o.status
ORDER BY coupon_code;