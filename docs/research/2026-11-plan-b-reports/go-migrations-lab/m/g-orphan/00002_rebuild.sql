-- +goose Up
CREATE TABLE orders_new LIKE orders;
INSERT INTO orders_new SELECT o.* FROM orders o INNER JOIN users u ON u.id=o.user_id;
RENAME TABLE orders TO orders_old, orders_new TO orders;
DROP TABLE orders_old;
-- +goose Down
SELECT 1;
