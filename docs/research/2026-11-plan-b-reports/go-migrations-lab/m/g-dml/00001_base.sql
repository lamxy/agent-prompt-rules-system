-- +goose Up
CREATE TABLE orders (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, sku VARCHAR(32) NOT NULL, note VARCHAR(64) NULL) ENGINE=InnoDB;
INSERT INTO orders (sku,note) VALUES ("a","n1"),("b","n2"),("c","n3");
-- +goose Down
DROP TABLE orders;
