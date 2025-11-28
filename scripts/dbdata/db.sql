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
INSERT INTO fruits(id, name, description) VALUES (3, 'Banana', 'Tropical yellow fruit');
INSERT INTO fruits(id, name, description) VALUES (4, 'Orange', 'Citrus fruit rich in vitamin C');
INSERT INTO fruits(id, name, description) VALUES (5, 'Strawberry', 'Sweet red berry');
INSERT INTO fruits(id, name, description) VALUES (6, 'Mango', 'Exotic tropical fruit');
INSERT INTO fruits(id, name, description) VALUES (7, 'Grape', 'Small purple or green fruit');
INSERT INTO fruits(id, name, description) VALUES (8, 'Pineapple', 'Large tropical fruit');
INSERT INTO fruits(id, name, description) VALUES (9, 'Watermelon', 'Large refreshing summer fruit');
INSERT INTO fruits(id, name, description) VALUES (10, 'Kiwi', 'Small fuzzy green fruit');

CREATE SEQUENCE fruits_seq START WITH 11 INCREMENT BY 1;

-- Stores
INSERT INTO stores(id, name, address, city, country, currency) VALUES (1, 'Store 1', '123 Main St', 'Anytown', 'USA', 'USD');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (2, 'Store 2', '456 Main St', 'Paris', 'France', 'EUR');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (3, 'Store 3', '789 Oak Ave', 'London', 'UK', 'GBP');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (4, 'Store 4', '321 Cherry Ln', 'Tokyo', 'Japan', 'JPY');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (5, 'Store 5', '555 Maple Dr', 'Toronto', 'Canada', 'CAD');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (6, 'Store 6', '888 Pine St', 'Sydney', 'Australia', 'AUD');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (7, 'Store 7', '999 Elm Rd', 'Berlin', 'Germany', 'EUR');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (8, 'Store 8', '147 Birch Blvd', 'Mexico City', 'Mexico', 'MXN');

CREATE SEQUENCE stores_seq START WITH 9 INCREMENT BY 1;

-- Prices
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 1, 1.29);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 2, 0.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 3, 0.59);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 4, 1.19);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 5, 3.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 1, 2.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 2, 1.19);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 3, 0.89);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 4, 1.79);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 6, 2.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (3, 1, 1.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (3, 2, 1.29);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (3, 5, 3.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (3, 7, 2.79);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (4, 1, 189.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (4, 3, 99.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (4, 4, 149.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (4, 8, 599.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (5, 1, 1.79);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (5, 2, 1.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (5, 5, 4.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (5, 9, 6.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (6, 1, 2.19);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (6, 6, 3.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (6, 8, 5.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (6, 10, 1.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (7, 2, 1.39);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (7, 4, 1.89);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (7, 7, 2.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (7, 9, 4.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (8, 1, 25.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (8, 3, 12.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (8, 6, 39.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (8, 8, 49.99);
