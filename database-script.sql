DROP DATABASE IF EXISTS srd_transportadora_final;
CREATE DATABASE srd_transportadora_final
  CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE srd_transportadora_final;

SELECT DATABASE();

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE person (
  person_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name      VARCHAR(160) NOT NULL,
  email     VARCHAR(180),
  phone     VARCHAR(40),
  nif       VARCHAR(20),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE addresses (
  address_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  person_id   BIGINT,
  line1       VARCHAR(160) NOT NULL,
  city        VARCHAR(100) NOT NULL,
  region      VARCHAR(100),
  postal_code VARCHAR(20),
  country     VARCHAR(60) NOT NULL DEFAULT 'Portugal',
  FOREIGN KEY (person_id) REFERENCES person(person_id)
) ENGINE=InnoDB;

CREATE TABLE drivers (
  person_id        BIGINT PRIMARY KEY,
  license_number   VARCHAR(60) NOT NULL UNIQUE,
  license_expires  DATE NOT NULL,
  active           BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (person_id) REFERENCES person(person_id)
) ENGINE=InnoDB;

CREATE TABLE vehicles (
  vehicle_id  BIGINT PRIMARY KEY AUTO_INCREMENT,
  plate       VARCHAR(20) NOT NULL UNIQUE,
  capacity_kg DECIMAL(12,3) NOT NULL,
  capacity_m3 DECIMAL(12,3) NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE product_types (
  product_type_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name            VARCHAR(80) NOT NULL UNIQUE,
  insurance_rate  DECIMAL(8,5) NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE shipments (
  shipment_id        BIGINT PRIMARY KEY AUTO_INCREMENT,
  shipper_id         BIGINT NOT NULL,
  origin_address_id  BIGINT NOT NULL,
  dest_address_id    BIGINT NOT NULL,
  product_type_id    BIGINT,
  goods_desc         VARCHAR(240) NOT NULL,
  weight_kg          DECIMAL(12,3) NOT NULL CHECK (weight_kg > 0),
  volume_m3          DECIMAL(12,3) NOT NULL DEFAULT 0,
  declared_value     DECIMAL(12,2) NOT NULL DEFAULT 0,
  created_at         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  delivered_at       DATETIME NULL,
  status             ENUM('CREATED','IN_TRANSIT','DELIVERED','CANCELLED') NOT NULL DEFAULT 'CREATED',
  FOREIGN KEY (shipper_id)        REFERENCES person(person_id),
  FOREIGN KEY (origin_address_id) REFERENCES addresses(address_id),
  FOREIGN KEY (dest_address_id)   REFERENCES addresses(address_id),
  FOREIGN KEY (product_type_id)   REFERENCES product_types(product_type_id),
  INDEX idx_ship_dates (created_at, delivered_at),
  INDEX idx_ship_status (status)
) ENGINE=InnoDB;

CREATE TABLE trips (
  trip_id         BIGINT PRIMARY KEY AUTO_INCREMENT,
  vehicle_id      BIGINT NOT NULL,
  driver_id       BIGINT NOT NULL,
  start_at        DATETIME NOT NULL,
  end_at          DATETIME,
  final_weight_kg DECIMAL(12,3) NOT NULL CHECK (final_weight_kg > 0),
  status          ENUM('OPEN','IN_TRANSIT','COMPLETED','CANCELLED') NOT NULL DEFAULT 'OPEN',
  FOREIGN KEY (vehicle_id) REFERENCES vehicles(vehicle_id),
  FOREIGN KEY (driver_id)  REFERENCES drivers(person_id)
) ENGINE=InnoDB;

SET FOREIGN_KEY_CHECKS = 1;

INSERT INTO product_types (name, insurance_rate) VALUES
  ('Standard',      0.0000),
  ('Refrigerated',  0.0020),
  ('Hazmat',        0.0050),
  ('Express',       0.0000);
