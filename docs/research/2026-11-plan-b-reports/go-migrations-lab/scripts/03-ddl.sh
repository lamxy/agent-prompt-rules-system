. /lab/scripts/lib.sh
newdb d1
t(){ echo ">> $*"; mysql -h$H -uroot d1 -e "$*" 2>&1; echo "[exit=$?]"; }
mysql -h$H -uroot -N -e "select version()"
mysql -h$H -uroot d1 -e "CREATE TABLE o (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL DEFAULT 'x', qty INT NOT NULL DEFAULT 1, note TEXT, FULLTEXT KEY ft (note)); CREATE TABLE p (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(50) NOT NULL DEFAULT 'x', qty INT NOT NULL DEFAULT 1);"
echo "=== L1 PlanetScale advice: explicit ALGORITHM plus LOCK=NONE on INSTANT"
t "ALTER TABLE p ADD COLUMN c1 INT NULL, ALGORITHM=INSTANT, LOCK=NONE"
t "ALTER TABLE p ADD COLUMN c1 INT NULL, ALGORITHM=INSTANT"
echo "=== L2 fail-fast cases"
t "ALTER TABLE p MODIFY qty BIGINT NOT NULL DEFAULT 1, ALGORITHM=INSTANT"
t "ALTER TABLE p MODIFY qty BIGINT NOT NULL DEFAULT 1, ALGORITHM=INPLACE, LOCK=NONE"
t "ALTER TABLE p ADD INDEX idx_q (qty), ALGORITHM=INSTANT"
t "ALTER TABLE p ADD INDEX idx_q (qty), ALGORITHM=INPLACE, LOCK=NONE"
t "ALTER TABLE p MODIFY name VARCHAR(60) NOT NULL DEFAULT 'x', ALGORITHM=INPLACE, LOCK=NONE"
t "ALTER TABLE p MODIFY name VARCHAR(100) NOT NULL DEFAULT 'x', ALGORITHM=INPLACE, LOCK=NONE"
t "ALTER TABLE p MODIFY name VARCHAR(100) NOT NULL DEFAULT 'x', ALGORITHM=COPY, LOCK=SHARED"
t "ALTER TABLE o ADD COLUMN c2 INT NULL, ALGORITHM=INSTANT"
t "ALTER TABLE p ADD COLUMN c3 INT NULL AFTER id, ALGORITHM=INSTANT"
echo "=== L3 repo rule merge into one ALTER vs INSTANT"
t "ALTER TABLE p ADD COLUMN c4 INT NULL, ADD INDEX idx_c4 (c4), ALGORITHM=INSTANT"
t "ALTER TABLE p ADD COLUMN c4 INT NULL, ADD INDEX idx_c4 (c4), ALGORITHM=INPLACE, LOCK=NONE"
echo "=== L4 single multi-clause ALTER is atomic on failure"
mysql -h$H -uroot d1 -e "CREATE TABLE u (id INT PRIMARY KEY, e VARCHAR(10)); INSERT INTO u VALUES (1,'d'),(2,'d');"
t "ALTER TABLE u ADD COLUMN x1 INT NULL, ADD UNIQUE INDEX uk (e)"
echo "columns after failed ALTER: $(qs d1 "SELECT GROUP_CONCAT(column_name) FROM information_schema.columns WHERE table_schema='d1' AND table_name='u'")"
echo "=== L5 INSTANT row version limit (add+drop loop)"
mysql -h$H -uroot d1 -e "CREATE TABLE v (id BIGINT PRIMARY KEY); INSERT INTO v VALUES (1);"
i=1; while [ $i -le 70 ]; do
  o=$(mysql -h$H -uroot d1 -e "ALTER TABLE v ADD COLUMN x$i INT NULL, ALGORITHM=INSTANT" 2>&1) || { echo "add #$i failed: $o"; break; }
  i=$((i+1))
done
echo "total_row_versions: $(qs information_schema "SELECT total_row_versions FROM innodb_tables WHERE name='d1/v'")"
o=$(mysql -h$H -uroot d1 -e "ALTER TABLE v ADD COLUMN y INT NULL" 2>&1); echo "no ALGORITHM clause after limit: exit=$? $o"; echo "total_row_versions after: $(qs information_schema "SELECT total_row_versions FROM innodb_tables WHERE name='d1/v'")"
echo "=== L6 default algorithm evidence: rows affected on 200k rows"
mysql -h$H -uroot d1 -e "CREATE TABLE big (id BIGINT AUTO_INCREMENT PRIMARY KEY, v CHAR(100) NOT NULL DEFAULT 'x'); INSERT INTO big(v) VALUES ('x');"
i=0; while [ $i -lt 18 ]; do mysql -h$H -uroot d1 -e "INSERT INTO big(v) SELECT v FROM big"; i=$((i+1)); done
echo "rows: $(qs d1 'SELECT COUNT(*) FROM big')"
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD COLUMN i1 INT NULL" 2>&1 | grep -E 'Query OK|Records'
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big ADD INDEX idx_v (v), ALGORITHM=INPLACE, LOCK=NONE" 2>&1 | grep -E 'Query OK|Records'
mysql -h$H -uroot d1 -vvv -e "ALTER TABLE big MODIFY v CHAR(120) NOT NULL DEFAULT 'x'" 2>&1 | grep -E 'Query OK|Records'
echo "=== L7 MDL: uncommitted reader blocks DDL, and DDL blocks later reads"
( mysql -h$H -uroot d1 -e "START TRANSACTION; SELECT COUNT(*) FROM p; SELECT SLEEP(6); COMMIT;" >/dev/null 2>&1 ) &
sleep 1
( s=$(date +%s); mysql -h$H -uroot d1 -e "ALTER TABLE p ADD COLUMN mdl INT NULL, ALGORITHM=INSTANT" 2>&1; echo "instant ALTER waited $(( $(date +%s)-s ))s" ) &
sleep 1
s=$(date +%s); mysql -h$H -uroot d1 -e "SELECT COUNT(*) FROM p" >/dev/null 2>&1; echo "later SELECT waited $(( $(date +%s)-s ))s"
wait
echo "--- with lock_wait_timeout=1"
( mysql -h$H -uroot d1 -e "START TRANSACTION; SELECT COUNT(*) FROM p; SELECT SLEEP(4); COMMIT;" >/dev/null 2>&1 ) &
sleep 1
mysql -h$H -uroot d1 -e "SET SESSION lock_wait_timeout=1; ALTER TABLE p ADD COLUMN mdl2 INT NULL, ALGORITHM=INSTANT" 2>&1; echo "[exit=$?]"
wait
