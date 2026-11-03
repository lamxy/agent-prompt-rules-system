-- +goose Up
ALTER TABLE orders ADD COLUMN status TINYINT UNSIGNED NOT NULL DEFAULT 0, ADD INDEX idx_status (status);
-- +goose Down
ALTER TABLE orders DROP INDEX idx_status, DROP COLUMN status;
