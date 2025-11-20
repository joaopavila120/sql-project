DROP DATABASE IF EXISTS coffee_ecommerce;
CREATE DATABASE coffee_ecommerce
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE coffee_ecommerce;

CREATE TABLE users (
  user_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  email          VARCHAR(180) NOT NULL UNIQUE,
  password_hash  VARCHAR(255) NOT NULL,
  role           ENUM('ADMIN','CUSTOMER') NOT NULL DEFAULT 'CUSTOMER',
  is_active      BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  last_login_at  DATETIME NULL
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id        BIGINT NOT NULL UNIQUE,
  full_name      VARCHAR(160) NOT NULL,
  phone          VARCHAR(40),
  tax_number     VARCHAR(32),
  date_of_birth  DATE,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
) ENGINE=InnoDB;

CREATE TABLE addresses (
  address_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT NOT NULL,
  line1         VARCHAR(160) NOT NULL,
  line2         VARCHAR(160),
  city          VARCHAR(100) NOT NULL,
  region        VARCHAR(100),
  postal_code   VARCHAR(20),
  country       VARCHAR(60) NOT NULL DEFAULT 'Portugal',
  address_type  ENUM('BILLING','SHIPPING','BOTH') NOT NULL DEFAULT 'SHIPPING',
  is_default    BOOLEAN NOT NULL DEFAULT FALSE,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  INDEX idx_addresses_customer (customer_id)
) ENGINE=InnoDB;

CREATE TABLE product_categories (
  category_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  name                 VARCHAR(120) NOT NULL UNIQUE,
  description          VARCHAR(255),
  parent_category_id   BIGINT NULL,
  FOREIGN KEY (parent_category_id) REFERENCES product_categories(category_id)
) ENGINE=InnoDB;

CREATE TABLE brands (
  brand_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  name         VARCHAR(120) NOT NULL UNIQUE,
  description  VARCHAR(255),
  country      VARCHAR(80)
) ENGINE=InnoDB;

CREATE TABLE coffee_types (
  coffee_type_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(120) NOT NULL UNIQUE,
  description     VARCHAR(255)
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  category_id       BIGINT NOT NULL,
  brand_id          BIGINT,
  coffee_type_id    BIGINT,
  name              VARCHAR(160) NOT NULL,
  description       TEXT,
  price_eur         DECIMAL(10,2) NOT NULL CHECK (price_eur >= 0),
  sku               VARCHAR(64) UNIQUE,
  weight_grams      INT,
  is_coffee         BOOLEAN NOT NULL DEFAULT TRUE,
  is_active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        DATETIME NULL,
  FOREIGN KEY (category_id)    REFERENCES product_categories(category_id),
  FOREIGN KEY (brand_id)       REFERENCES brands(brand_id),
  FOREIGN KEY (coffee_type_id) REFERENCES coffee_types(coffee_type_id),
  INDEX idx_products_category (category_id),
  INDEX idx_products_active (is_active)
) ENGINE=InnoDB;

CREATE TABLE stock (
  stock_id          BIGINT PRIMARY KEY AUTO_INCREMENT,
  product_id        BIGINT NOT NULL UNIQUE,
  quantity          INT NOT NULL DEFAULT 0 CHECK (quantity >= 0),
  reserved_quantity INT NOT NULL DEFAULT 0 CHECK (reserved_quantity >= 0),
  updated_at        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (product_id) REFERENCES products(product_id)
) ENGINE=InnoDB;

CREATE TABLE discount_coupons (
  coupon_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  code             VARCHAR(60) NOT NULL UNIQUE,
  description      VARCHAR(255),
  discount_type    ENUM('PERCENTAGE','FIXED') NOT NULL,
  discount_value   DECIMAL(10,2) NOT NULL CHECK (discount_value >= 0),
  max_uses         INT,
  times_used       INT NOT NULL DEFAULT 0 CHECK (times_used >= 0),
  valid_from       DATETIME,
  valid_to         DATETIME,
  min_order_value  DECIMAL(10,2),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE orders (
  order_id             BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id          BIGINT NOT NULL,
  billing_address_id   BIGINT NOT NULL,
  shipping_address_id  BIGINT NOT NULL,
  coupon_id            BIGINT,
  order_date           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status               ENUM('PENDING','PAID','SHIPPED','DELIVERED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  subtotal_eur         DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (subtotal_eur >= 0),
  discount_total_eur   DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (discount_total_eur >= 0),
  shipping_fee_eur     DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (shipping_fee_eur >= 0),
  total_eur            DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (total_eur >= 0),
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id)          REFERENCES customers(customer_id),
  FOREIGN KEY (billing_address_id)   REFERENCES addresses(address_id),
  FOREIGN KEY (shipping_address_id)  REFERENCES addresses(address_id),
  FOREIGN KEY (coupon_id)            REFERENCES discount_coupons(coupon_id),
  INDEX idx_orders_customer (customer_id),
  INDEX idx_orders_status_date (status, order_date)
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id    BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id         BIGINT NOT NULL,
  product_id       BIGINT NOT NULL,
  quantity         INT NOT NULL CHECK (quantity > 0),
  unit_price_eur   DECIMAL(10,2) NOT NULL CHECK (unit_price_eur >= 0),
  line_total_eur   DECIMAL(12,2) GENERATED ALWAYS AS (quantity * unit_price_eur) STORED,
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  INDEX idx_order_items_order (order_id),
  INDEX idx_order_items_product (product_id)
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id        BIGINT NOT NULL,
  payment_method  ENUM('CREDIT_CARD','PAYPAL','MBWAY','BANK_TRANSFER') NOT NULL,
  amount_eur      DECIMAL(12,2) NOT NULL CHECK (amount_eur >= 0),
  status          ENUM('PENDING','AUTHORIZED','PAID','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
  transaction_ref VARCHAR(120),
  payment_date    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id) REFERENCES orders(order_id),
  INDEX idx_payments_order (order_id),
  INDEX idx_payments_status (status)
) ENGINE=InnoDB;

CREATE TABLE carriers (
  carrier_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  name         VARCHAR(160) NOT NULL,
  phone        VARCHAR(40),
  website_url  VARCHAR(255),
  is_active    BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE shipments (
  shipment_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id         BIGINT NOT NULL,
  carrier_id       BIGINT NOT NULL,
  tracking_code    VARCHAR(120),
  status           ENUM('PENDING','SHIPPED','IN_TRANSIT','DELIVERED','RETURNED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  shipped_at       DATETIME,
  delivered_at     DATETIME,
  shipping_cost_eur DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (shipping_cost_eur >= 0),
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (carrier_id) REFERENCES carriers(carrier_id),
  INDEX idx_shipments_order (order_id),
  INDEX idx_shipments_status (status)
) ENGINE=InnoDB;

CREATE TABLE product_reviews (
  review_id     BIGINT PRIMARY KEY AUTO_INCREMENT,
  product_id    BIGINT NOT NULL,
  customer_id   BIGINT NOT NULL,
  rating        TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title         VARCHAR(160),
  comment       VARCHAR(1000),
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_approved   BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (product_id)  REFERENCES products(product_id),
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  INDEX idx_reviews_product (product_id),
  INDEX idx_reviews_customer (customer_id),
  INDEX idx_reviews_rating (rating)
) ENGINE=InnoDB;

CREATE TABLE shopping_carts (
  cart_id      BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id  BIGINT NOT NULL,
  status       ENUM('OPEN','CONVERTED','ABANDONED') NOT NULL DEFAULT 'OPEN',
  created_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  INDEX idx_carts_customer_status (customer_id, status)
) ENGINE=InnoDB;

CREATE TABLE shopping_cart_items (
  cart_item_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  cart_id        BIGINT NOT NULL,
  product_id     BIGINT NOT NULL,
  quantity       INT NOT NULL CHECK (quantity > 0),
  added_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (cart_id)    REFERENCES shopping_carts(cart_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id),
  UNIQUE KEY uk_cart_product (cart_id, product_id)
) ENGINE=InnoDB;

CREATE TABLE favorites (
  favorite_id   BIGINT PRIMARY KEY AUTO_INCREMENT,
  customer_id   BIGINT NOT NULL,
  product_id    BIGINT NOT NULL,
  created_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  FOREIGN KEY (product_id)  REFERENCES products(product_id),
  UNIQUE KEY uk_favorites_customer_product (customer_id, product_id)
) ENGINE=InnoDB;

CREATE TABLE access_logs (
  access_log_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id        BIGINT,
  ip_address     VARCHAR(45),
  user_agent     VARCHAR(255),
  request_path   VARCHAR(255),
  http_method    VARCHAR(10),
  success        BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id),
  INDEX idx_access_logs_user (user_id),
  INDEX idx_access_logs_created (created_at)
) ENGINE=InnoDB;

CREATE TABLE transaction_logs (
  transaction_log_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_id            BIGINT,
  payment_id          BIGINT,
  user_id             BIGINT,
  log_type            ENUM('ORDER_STATUS','PAYMENT_STATUS','STOCK_CHANGE','COUPON','OTHER') NOT NULL,
  old_value           VARCHAR(1000),
  new_value           VARCHAR(1000),
  message             VARCHAR(1000),
  created_at          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (order_id)   REFERENCES orders(order_id),
  FOREIGN KEY (payment_id) REFERENCES payments(payment_id),
  FOREIGN KEY (user_id)    REFERENCES users(user_id),
  INDEX idx_tx_logs_type_created (log_type, created_at)
) ENGINE=InnoDB;