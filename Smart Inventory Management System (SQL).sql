CREATE DATABASE inventory_system;
USE inventory_system;
CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','staff') NOT NULL DEFAULT 'staff',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  category_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
);
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  supplier_name VARCHAR(150) NOT NULL,
  contact_name VARCHAR(100),
  address VARCHAR(255),
  phone VARCHAR(50),
  email VARCHAR(100)
);
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  product_name VARCHAR(150) NOT NULL,
  category_id INT,
  supplier_id INT,
  unit_price DECIMAL(10,2) NOT NULL,
  stock_quantity INT NOT NULL DEFAULT 0,
  reorder_level INT DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (category_id) REFERENCES categories(category_id),
  FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id)
);
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  email VARCHAR(100),
  phone VARCHAR(50),
  address VARCHAR(255)
);
CREATE TABLE sales (
  sale_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  customer_id INT,
  total_amount DECIMAL(12,2) NOT NULL,
  FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
CREATE TABLE sale_items (
  sale_item_id INT AUTO_INCREMENT PRIMARY KEY,
  sale_id INT,
  product_id INT,
  quantity INT NOT NULL,
  unit_price DECIMAL(10,2) NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales(sale_id),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);
CREATE TABLE stock_movements (
  movement_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT,
  change_quantity INT NOT NULL,  -- positive for restock, negative for sale
  movement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note VARCHAR(255),
  FOREIGN KEY (product_id) REFERENCES products(product_id)
);
INSERT INTO users (username, password_hash, role) VALUES
('admin1', SHA2('admin123',256), 'admin'),
('staff1', SHA2('staff123',256), 'staff');

-- Insert categories
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic gadgets and devices'),
('Apparel', 'Clothing and accessories'),
('Groceries', 'Daily use grocery items');

-- Insert suppliers
INSERT INTO suppliers (supplier_name, contact_name, address, phone, email) VALUES
('TechSupply Co.', 'Alice Smith', '123 Tech Park, City', '1234567890', 'alice@techsupply.com'),
('ClothWorld', 'Bob Brown', '45 Fashion Ave, City', '2345678901', 'bob@clothworld.com'),
('FreshFoods Inc.', 'Carol White', '67 Market Road, City', '3456789012', 'carol@freshfoods.com');

-- Insert products
INSERT INTO products (product_name, category_id, supplier_id, unit_price, stock_quantity, reorder_level) VALUES
('Smartphone X', 1, 1, 25000.00, 50, 10),
('Laptop Pro', 1, 1, 45000.00, 20, 5),
('T-Shirt Classic', 2, 2, 499.00, 200, 20),
('Jeans Slim', 2, 2, 1299.00, 100, 15),
('Rice (5kg)', 3, 3, 350.00, 500, 100),
('Cooking Oil (1L)', 3, 3, 120.00, 300, 50);

-- Insert customers
INSERT INTO customers (name, email, phone, address) VALUES
('John Doe', 'john@example.com', '9876543210', '12 Elm Street, City'),
('Jane Roe', 'jane@example.com', '8765432109', '34 Maple Avenue, City'),
('Sam Green', 'sam@example.com', '7654321098', '56 Oak Road, City');

-- Insert sales and sale_items (two sample sales)
INSERT INTO sales (sale_date, customer_id, total_amount) VALUES
('2025-10-01 10:00:00', 1, 26000.00),
('2025-10-02 14:30:00', 2, 1800.00);

-- Link sale items
INSERT INTO sale_items (sale_id, product_id, quantity, unit_price) VALUES
(1, 1, 1, 25000.00),
(1, 3, 2, 499.00),  -- customer bought 2 T-Shirts
(2, 3, 1, 499.00),
(2, 6, 1, 120.00);  -- cooking oil

-- Insert stock movements to reflect the above sales (subtract)
INSERT INTO stock_movements (product_id, change_quantity, note) VALUES
(1, -1, 'Sale #1 - Smartphone X'),
(3, -2, 'Sale #1 - T-Shirt Classic'),
(3, -1, 'Sale #2 - T-Shirt Classic'),
(6, -1, 'Sale #2 - Cooking Oil');

-- Also, insert some restocking movements
INSERT INTO stock_movements (product_id, change_quantity, note) VALUES
(1, 10, 'Restock Smartphones'),
(3, 50, 'Restock T-Shirts'),
(6, 100, 'Restock Cooking Oil');

-- ========== Example Queries ==========

-- 1. Show all products with category names
SELECT p.product_id, p.product_name, c.category_name, p.unit_price, p.stock_quantity
FROM products p
LEFT JOIN categories c ON p.category_id = c.category_id;

-- 2. Get all sales with customer and items
SELECT s.sale_id, s.sale_date, c.name AS customer_name, si.product_id, pr.product_name, si.quantity, si.unit_price
FROM sales s
JOIN customers c ON s.customer_id = c.customer_id
JOIN sale_items si ON s.sale_id = si.sale_id
JOIN products pr ON si.product_id = pr.product_id
ORDER BY s.sale_id;

-- 3. Products below reorder level
SELECT product_id, product_name, stock_quantity, reorder_level
FROM products
WHERE stock_quantity <= reorder_level;

-- 4. Total sales per product
SELECT pr.product_id, pr.product_name, SUM(si.quantity) AS total_sold,
       SUM(si.quantity * si.unit_price) AS revenue
FROM sale_items si
JOIN products pr ON si.product_id = pr.product_id
GROUP BY pr.product_id, pr.product_name
ORDER BY revenue DESC;

-- 5. Stock movement history for a product (for example product_id = 1)
SELECT * FROM stock_movements WHERE product_id = 1 ORDER BY movement_date DESC;
