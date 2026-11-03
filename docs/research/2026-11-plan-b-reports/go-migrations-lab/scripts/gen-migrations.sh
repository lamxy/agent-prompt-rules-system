#!/bin/sh
# Generates all test migrations under ../m. Runs on host; only touches this lab directory.
set -eu
L=$(cd "$(dirname "$0")/.." && pwd)
M=$L/m
mkdir -p "$M/g-fail" "$M/g-fail-notx" "$M/g-dml" "$M/g-good" "$M/m-fail" "$M/m-dml" "$M/m-dml-tx" "$M/g-baddown" "$M/g-dataloss" "$M/g-orphan" "$M/g-seedfail"

BASE='CREATE TABLE orders (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, sku VARCHAR(32) NOT NULL, note VARCHAR(64) NULL) ENGINE=InnoDB;
INSERT INTO orders (sku,note) VALUES ("a","n1"),("b","n2"),("c","n3");'
FAILUP='ALTER TABLE orders ADD COLUMN a1 INT NULL;
INSERT INTO orders (sku) VALUES ("after-first-ddl");
CREATE TABLE audit_x (id INT PRIMARY KEY);
INSERT INTO no_such_table VALUES (1);
ALTER TABLE orders ADD COLUMN a2 INT NULL;'
FAILDN='ALTER TABLE orders DROP COLUMN a2;
DROP TABLE audit_x;
ALTER TABLE orders DROP COLUMN a1;'
DML='INSERT INTO orders (sku) VALUES ("dml1");
UPDATE orders SET note="touched";
INSERT INTO no_such_table VALUES (1);'

for d in g-fail g-fail-notx g-dml; do
  printf -- '-- +goose Up\n%s\n-- +goose Down\nDROP TABLE orders;\n' "$BASE" > "$M/$d/00001_base.sql"
done
for d in m-fail m-dml m-dml-tx; do
  printf '%s\n' "$BASE" > "$M/$d/000001_base.up.sql"
  printf 'DROP TABLE orders;\n' > "$M/$d/000001_base.down.sql"
done
printf -- '-- +goose Up\n%s\n-- +goose Down\n%s\n' "$FAILUP" "$FAILDN" > "$M/g-fail/00002_multi.sql"
printf -- '-- +goose NO TRANSACTION\n-- +goose Up\n%s\n-- +goose Down\n%s\n' "$FAILUP" "$FAILDN" > "$M/g-fail-notx/00002_multi.sql"
printf '%s\n' "$FAILUP" > "$M/m-fail/000002_multi.up.sql"
printf '%s\n' "$FAILDN" > "$M/m-fail/000002_multi.down.sql"
printf -- '-- +goose Up\n%s\n-- +goose Down\nSELECT 1;\n' "$DML" > "$M/g-dml/00002_dml.sql"
printf '%s\n' "$DML" > "$M/m-dml/000002_dml.up.sql"
printf 'SELECT 1;\n' > "$M/m-dml/000002_dml.down.sql"
printf 'START TRANSACTION;\n%s\nCOMMIT;\n' "$DML" > "$M/m-dml-tx/000002_dml.up.sql"
printf 'SELECT 1;\n' > "$M/m-dml-tx/000002_dml.down.sql"

for d in g-good g-baddown g-dataloss g-orphan g-seedfail; do
  cat > "$M/$d/00001_base.sql" <<'E'
-- +goose Up
CREATE TABLE users (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, email VARCHAR(64) NOT NULL) ENGINE=InnoDB;
CREATE TABLE orders (id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNSIGNED NOT NULL, note VARCHAR(64) NULL, KEY idx_user (user_id)) ENGINE=InnoDB;
-- +goose Down
DROP TABLE orders;
DROP TABLE users;
E
done
cat > "$M/g-good/00002_add.sql" <<'E'
-- +goose Up
ALTER TABLE orders ADD COLUMN status TINYINT UNSIGNED NOT NULL DEFAULT 0, ADD INDEX idx_status (status);
-- +goose Down
ALTER TABLE orders DROP INDEX idx_status, DROP COLUMN status;
E
cat > "$M/g-baddown/00002_add.sql" <<'E'
-- +goose Up
ALTER TABLE orders ADD COLUMN status TINYINT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE orders ADD INDEX idx_note (note);
-- +goose Down
ALTER TABLE orders DROP COLUMN status;
E
cat > "$M/g-dataloss/00002_dropnote.sql" <<'E'
-- +goose Up
ALTER TABLE orders DROP COLUMN note;
-- +goose Down
ALTER TABLE orders ADD COLUMN note VARCHAR(64) NULL;
E
cat > "$M/g-orphan/00002_rebuild.sql" <<'E'
-- +goose Up
CREATE TABLE orders_new LIKE orders;
INSERT INTO orders_new SELECT o.* FROM orders o INNER JOIN users u ON u.id=o.user_id;
RENAME TABLE orders TO orders_old, orders_new TO orders;
DROP TABLE orders_old;
-- +goose Down
SELECT 1;
E
cat > "$M/g-seedfail/00002_uniq.sql" <<'E'
-- +goose Up
ALTER TABLE users ADD COLUMN nick VARCHAR(16) NULL;
ALTER TABLE users ADD UNIQUE INDEX uk_email (email);
-- +goose Down
ALTER TABLE users DROP INDEX uk_email;
ALTER TABLE users DROP COLUMN nick;
E
find "$M" -type f | wc -l
