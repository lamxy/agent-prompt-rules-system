. /lab/scripts/lib.sh
mysql -h$H -uroot -N -e "select version(), @@sql_mode, @@autocommit"
echo "=== G1 goose default tx: DDL then failure"; newdb g1
g g1 g-fail up; state g1; q g1 "SELECT version_id,is_applied FROM goose_db_version"; g g1 g-fail status; g g1 g-fail version
echo "--- G1 rerun up"; g g1 g-fail up; state g1
echo "--- G1 goose validate (does it catch anything?)"; g g1 g-fail validate
echo "=== G2 goose down right after failed migration (separate db)"; newdb g2
g g2 g-fail up >/dev/null; g g2 g-fail down; state g2; q g2 "SELECT version_id,is_applied FROM goose_db_version"
echo "=== G3 goose NO TRANSACTION"; newdb g3
g g3 g-fail-notx up; state g3; q g3 "SELECT version_id,is_applied FROM goose_db_version"
echo "=== G4 goose DML only failure (tx rollback)"; newdb g4
g g4 g-dml up; state g4; q g4 "SELECT version_id,is_applied FROM goose_db_version"
echo "=== G5 goose without multiStatements in DSN"; newdb g5
gns g5 g-fail up; state g5
echo "=== G6 goose recover: manual cleanup + fixed file then up"; newdb g6
g g6 g-fail up >/dev/null
mysql -h$H -uroot g6 -e "ALTER TABLE orders DROP COLUMN a1; DROP TABLE audit_x; DELETE FROM orders WHERE sku='after-first-ddl';"
mkdir -p /tmp/gfix; cp /lab/m/g-fail/*.sql /tmp/gfix/; sed -i '/no_such_table/d' /tmp/gfix/00002_multi.sql
/lab/bin/goose -env=none -no-color -dir /tmp/gfix mysql "root:$P@tcp($H:3306)/g6?parseTime=true" up 2>&1; echo "[exit=$?]"; state g6

echo "=== M1 migrate: DDL then failure"; newdb m1
m m1 m-fail up; state m1; q m1 "SELECT version,dirty FROM schema_migrations"; m m1 m-fail version
echo "--- M1 rerun up"; m m1 m-fail up
echo "--- M1 down while dirty"; m m1 m-fail down 1
echo "--- M1 force 1 and up again (no cleanup)"; m m1 m-fail force 1; q m1 "SELECT version,dirty FROM schema_migrations"; m m1 m-fail up; state m1; q m1 "SELECT version,dirty FROM schema_migrations"
echo "=== M2 force 2 then down (down file assumes full apply)"; newdb m2
m m2 m-fail up >/dev/null; m m2 m-fail force 2; m m2 m-fail down 1; state m2; q m2 "SELECT version,dirty FROM schema_migrations"
echo "=== M3 migrate DML only, no wrap"; newdb m3
m m3 m-dml up; state m3; q m3 "SELECT version,dirty FROM schema_migrations"
echo "=== M4 migrate DML wrapped START TRANSACTION"; newdb m4
m m4 m-dml-tx up; state m4; q m4 "SELECT version,dirty FROM schema_migrations"
