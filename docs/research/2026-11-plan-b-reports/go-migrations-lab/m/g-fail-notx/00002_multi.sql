-- +goose NO TRANSACTION
-- +goose Up
ALTER TABLE orders ADD COLUMN a1 INT NULL;
INSERT INTO orders (sku) VALUES ("after-first-ddl");
CREATE TABLE audit_x (id INT PRIMARY KEY);
INSERT INTO no_such_table VALUES (1);
ALTER TABLE orders ADD COLUMN a2 INT NULL;
-- +goose Down
ALTER TABLE orders DROP COLUMN a2;
DROP TABLE audit_x;
ALTER TABLE orders DROP COLUMN a1;
