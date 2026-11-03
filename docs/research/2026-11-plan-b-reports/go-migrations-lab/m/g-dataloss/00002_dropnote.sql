-- +goose Up
ALTER TABLE orders DROP COLUMN note;
-- +goose Down
ALTER TABLE orders ADD COLUMN note VARCHAR(64) NULL;
