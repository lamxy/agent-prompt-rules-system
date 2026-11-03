. /lab/scripts/lib.sh
# mysql:8.0 image has no diff; this shim compares whole files and prints differing lines.
# Snapshots persist in /lab/out/snap so they are re-checked with real diff on the host.
S=/lab/out/snap; mkdir -p $S
diff(){ if [ "$(cat "$1")" = "$(cat "$2")" ]; then return 0; fi; grep -vxFf "$2" "$1" | sed 's/^/- /'; grep -vxFf "$1" "$2" | sed 's/^/+ /'; return 1; }
seed(){ db=$1; mysql -h$H -uroot "$db" -e "INSERT INTO users(email) VALUES('a@x'),('b@x'),('c@x'); INSERT INTO orders(user_id,note) VALUES (1,'n1'),(2,'n2'),(3,'n3'),(99,'orphan'),(1,'n5');"; }
# roundtrip: base up, seed, snapshot, up latest, compare, down, compare
rt(){ db=$1; dir=$2; newdb $db; g $db $dir up-to 1 >/dev/null; seed $db
  snap $db > $S/$db.before.sql; counts $db > $S/$db.c0; sums $db > $S/$db.s0
  echo "--- up:"; g $db $dir up | tail -2; counts $db > $S/$db.c1
  echo "--- rowcount before vs after up:"; diff $S/$db.c0 $S/$db.c1 && echo "rowcount identical"
  echo "--- down:"; g $db $dir down | tail -2
  snap $db > $S/$db.after.sql; counts $db > $S/$db.c2; sums $db > $S/$db.s2
  echo "--- schema diff before vs after up+down:"; diff $S/$db.before.sql $S/$db.after.sql && echo "schema identical"
  echo "--- rowcount after up+down:"; diff $S/$db.c0 $S/$db.c2 && echo "rowcount identical"
  echo "--- checksum after up+down:"; diff $S/$db.s0 $S/$db.s2 && echo "checksum identical"
  echo "--- snapshot size: $(wc -l < $S/$db.before.sql) lines; dump stderr: $(cat /tmp/snap.err)"
}
echo "=== C1 good migration"; rt c1 g-good
echo "=== C2 down forgets index"; rt c2 g-baddown
echo "=== C3 down re-adds dropped column: data lost, schema same"; rt c3 g-dataloss; qs c3 "SELECT id,note FROM orders"
echo "=== C4 rebuild via INNER JOIN drops orphan row (forward only)"; newdb c4; g c4 g-orphan up-to 1 >/dev/null; seed c4; counts c4 > $S/c4.c0; g c4 g-orphan up | tail -2; counts c4 > $S/c4.c1; diff $S/c4.c0 $S/c4.c1 || echo "ROWCOUNT DIFFERS"
echo "=== C5 same migration on empty vs seeded (shadow value)"
newdb c5e; g c5e g-seedfail up | tail -2; state c5e | head -2
newdb c5s; g c5s g-seedfail up-to 1 >/dev/null; mysql -h$H -uroot c5s -e "INSERT INTO users(email) VALUES('dup@x'),('dup@x');"; g c5s g-seedfail up | tail -3; qs c5s "SHOW COLUMNS FROM users" ; q c5s "SELECT version_id FROM goose_db_version"
echo "=== C6 AUTO_INCREMENT noise without normalisation"
newdb c6; g c6 g-good up-to 1 >/dev/null; A=$(mysqldump -h$H -uroot --no-data --skip-comments --skip-dump-date c6 orders 2>/dev/null | grep -c 'AUTO_INCREMENT='); seed c6; mysql -h$H -uroot -e "ANALYZE TABLE c6.orders" >/dev/null; B=$(mysqldump -h$H -uroot --no-data --skip-comments --skip-dump-date c6 orders 2>/dev/null | grep -o 'AUTO_INCREMENT=[0-9]*'); echo "before-seed lines with AUTO_INCREMENT=: $A; after-seed: $B"
echo "=== C7 table_rows estimate vs exact COUNT"
newdb c7; mysql -h$H -uroot c7 -e "CREATE TABLE t (id BIGINT AUTO_INCREMENT PRIMARY KEY, v CHAR(100) NOT NULL DEFAULT 'x'); INSERT INTO t(v) VALUES ('x'); INSERT INTO t(v) SELECT v FROM t;"
i=0; while [ $i -lt 16 ]; do mysql -h$H -uroot c7 -e "INSERT INTO t(v) SELECT v FROM t"; i=$((i+1)); done
mysql -h$H -uroot c7 -e "ANALYZE TABLE t" >/dev/null
echo "COUNT=$(qs c7 'SELECT COUNT(*) FROM t') information_schema.table_rows=$(qs c7 "SELECT table_rows FROM information_schema.tables WHERE table_schema='c7' AND table_name='t'")"
echo "=== C8 shadow copy via mysqldump|mysql then migrate shadow only"
newdb c8src; g c8src g-good up-to 1 >/dev/null; seed c8src; newdb c8shadow
mysqldump -h$H -uroot --single-transaction --no-tablespaces --set-gtid-purged=OFF c8src 2>/dev/null | mysql -h$H -uroot c8shadow
g c8shadow g-good up | tail -2
echo "src goose version: $(qs c8src 'SELECT MAX(version_id) FROM goose_db_version'); shadow: $(qs c8shadow 'SELECT MAX(version_id) FROM goose_db_version')"
echo "src status col: $(qs c8src "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='c8src' AND column_name='status'"); shadow: $(qs c8shadow "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema='c8shadow' AND column_name='status'")"
counts c8src > $S/a; counts c8shadow > $S/b; diff $S/a $S/b && echo "rowcount src==shadow"
