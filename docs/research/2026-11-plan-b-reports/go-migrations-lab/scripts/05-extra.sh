. /lab/scripts/lib.sh
echo "=== V1 goose validate, offline form (no driver/DSN)"
/lab/bin/goose -env=none -no-color -dir /lab/m/g-fail validate 2>&1; echo "[exit=$?]"
mkdir -p /tmp/badparse; printf -- '-- +goose Down\nDROP TABLE x;\n-- +goose Up\nCREATE TABLE x (id INT);\n' > /tmp/badparse/00001_b.sql
/lab/bin/goose -env=none -no-color -dir /tmp/badparse validate 2>&1; echo "[exit=$?] (annotation order wrong)"
echo "=== V2 merged ALTER vs row versions: does adding an index beside a column rebuild?"
rv(){ qs information_schema "SELECT total_row_versions FROM innodb_tables WHERE name='d1/big'"; }
echo "row versions start: $(rv)"
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD COLUMN s1 INT NULL" 2>&1 | grep -E 'Query OK'; echo "after single ADD COLUMN: $(rv)"
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD COLUMN s2 INT NULL" 2>&1 | grep -E 'Query OK'; echo "after second ADD COLUMN: $(rv)"
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD INDEX idx_s2 (s2)" 2>&1 | grep -E 'Query OK'; echo "after separate ADD INDEX: $(rv)"
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD COLUMN s3 INT NULL, ADD INDEX idx_s3 (s3)" 2>&1 | grep -E 'Query OK'; echo "after merged ADD COLUMN + ADD INDEX: $(rv)"
