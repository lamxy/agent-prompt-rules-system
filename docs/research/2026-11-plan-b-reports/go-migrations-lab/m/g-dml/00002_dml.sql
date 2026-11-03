-- +goose Up
INSERT INTO orders (sku) VALUES ("dml1");
UPDATE orders SET note="touched";
INSERT INTO no_such_table VALUES (1);
-- +goose Down
SELECT 1;
