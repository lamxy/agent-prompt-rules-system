-- +goose Up
ALTER TABLE users ADD COLUMN nick VARCHAR(16) NULL;
ALTER TABLE users ADD UNIQUE INDEX uk_email (email);
-- +goose Down
ALTER TABLE users DROP INDEX uk_email;
ALTER TABLE users DROP COLUMN nick;
