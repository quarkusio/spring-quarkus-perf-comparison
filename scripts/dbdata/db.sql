-- Create tables

CREATE TABLE fruits (
		id bigint NOT NULL,
		description VARCHAR(255),
		name VARCHAR(255) NOT NULL UNIQUE,
		PRIMARY KEY (id)
);

CREATE TABLE store_fruit_prices (
		price numeric(12,2) NOT NULL,
		fruit_id bigint NOT NULL,
		store_id bigint NOT NULL,
		PRIMARY KEY (fruit_id, store_id)
);

CREATE TABLE stores (
		id bigint NOT NULL,
		ADDress VARCHAR(255) NOT NULL,
		city VARCHAR(255) NOT NULL,
		country VARCHAR(255) NOT NULL,
		currency VARCHAR(255) NOT NULL,
		name VARCHAR(255) NOT NULL UNIQUE,
		PRIMARY KEY (id)
);

ALTER TABLE IF exists store_fruit_prices
	 ADD CONSTRAINT fruit_id_fk
	 FOREIGN KEY (fruit_id)
	 REFERENCES fruits;

ALTER TABLE IF exists store_fruit_prices
	 ADD CONSTRAINT store_id_fk
	 FOREIGN KEY (store_id)
	 REFERENCES stores;

-- Fruits
INSERT INTO fruits(id, name, description) VALUES (1, 'Apple', 'Hearty fruit');
INSERT INTO fruits(id, name, description) VALUES (2, 'Pear', 'Juicy fruit');
CREATE SEQUENCE fruits_seq START WITH 1 INCREMENT BY 1;

-- Stores
INSERT INTO stores(id, name, ADDress, city, country, currency) VALUES (1, 'Store 1', '123 Main St', 'Anytown', 'USA', 'USD');
INSERT INTO stores(id, name, ADDress, city, country, currency) VALUES (2, 'Store 2', '456 Main St', 'Paris', 'France', 'EUR');
CREATE SEQUENCE stores_seq START WITH 1 INCREMENT BY 1;

-- Prices
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 1, 1.29);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 2, 0.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 1, 2.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 2, 1.19);
