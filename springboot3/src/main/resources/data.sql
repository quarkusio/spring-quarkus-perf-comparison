-- Fruits
INSERT INTO fruits(id, name, description) VALUES (1, 'Apple', 'Hearty fruit');
INSERT INTO fruits(id, name, description) VALUES (2, 'Pear', 'Juicy fruit');

ALTER SEQUENCE fruits_seq RESTART WITH 3;

-- Stores
INSERT INTO stores(id, name, address, city, country, currency) VALUES (1, 'Store 1', '123 Main St', 'Anytown', 'USA', 'USD');
INSERT INTO stores(id, name, address, city, country, currency) VALUES (2, 'Store 2', '456 Main St', 'Paris', 'France', 'EUR');

ALTER SEQUENCE stores_seq RESTART WITH 3;

-- Prices
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 1, 1.29);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (1, 2, 0.99);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 1, 2.49);
INSERT INTO store_fruit_prices(store_id, fruit_id, price) VALUES (2, 2, 1.19);