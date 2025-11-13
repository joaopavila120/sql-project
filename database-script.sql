-- TABLES

CREATE TABLE person(
	person_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(160) NOT NULL,
    email VARCHAR(180),
    phone VARCHAR(40),
    nif VARCHAR(10), -- PORTUGAL TAX ID 
    CREATED_AT DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE address(
	address_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    person_id BIGINT,
	line1 VARCHAR(160) NOT NULL,
	city VARCHAR(100) NOT NULL,
	region VARCHAR(100),
	postal_code VARCHAR(20),
	country VARCHAR(60) NOT NULL DEFAULT 'Portugal',
	FOREIGN KEY (person_id) REFERENCES person(person_id)
) ENGINE=InnoDB;

-- Drivers
CREATE TABLE drivers (
  person_id BIGINT PRIMARY KEY,
  license_number VARCHAR(60) NOT NULL UNIQUE,
  license_expires DATE NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  FOREIGN KEY (person_id) REFERENCES person(person_id)
) ENGINE=InnoDB;

-- vehicles
CREATE TABLE vehicles(
	vehicle_id BIGINT PRIMARY KEY AUTO_INCREMENT,
    plate VARCHAR(20) NOT NULL UNIQUE,
    capacity_kg DECIMAL(12, 3) NOT NULL, 
    capacity_m3 DECIMAL(12, 3) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;


CREATE TABLE product_types (
  product_type_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(80) NOT NULL UNIQUE,   -- ex.: 'Refrigerated', 'Hazmat', 'Express'
  insurance_rate DECIMAL(8,5) NOT NULL DEFAULT 0 -- % sobre declared_value (ex.: 0.005 = 0.5%)
) ENGINE=InnoDB;

INSERT INTO product_types (name, insurance_rate) VALUES
('Standard',     0.0000),
('Refrigerated',  0.0020),
('Hazmat',        0.0050),
('Express',       0.0000);
