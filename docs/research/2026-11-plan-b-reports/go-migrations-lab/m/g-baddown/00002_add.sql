-- +goose Up
ALTER TABLE orders ADD COLUMN status TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE orders ADD INDEX idx_note (note);
-- +goose Down
ALTER TABLE orders DROP COLUMN status;
