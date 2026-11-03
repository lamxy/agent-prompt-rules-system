H=mig-probe-mysql; P=fake-test-pass
export MYSQL_PWD=$P
q(){ d=$1; shift; mysql -h$H -uroot --table "$d" -e "$*" 2>&1; }
qs(){ d=$1; shift; mysql -h$H -uroot -N -B "$d" -e "$*" 2>&1; }
newdb(){ mysql -h$H -uroot -e "DROP DATABASE IF EXISTS $1; CREATE DATABASE $1;" 2>&1; }
g(){ db=$1; dir=$2; shift 2; /lab/bin/goose -env=none -no-color -dir /lab/m/$dir mysql "root:$P@tcp($H:3306)/$db?parseTime=true&multiStatements=true" "$@" 2>&1; echo "[exit=$?]"; }
gns(){ db=$1; dir=$2; shift 2; /lab/bin/goose -env=none -no-color -dir /lab/m/$dir mysql "root:$P@tcp($H:3306)/$db?parseTime=true" "$@" 2>&1; echo "[exit=$?]"; }
m(){ db=$1; dir=$2; shift 2; /lab/bin/migrate -path /lab/m/$dir -database "mysql://root:$P@tcp($H:3306)/$db" "$@" 2>&1; echo "[exit=$?]"; }
# schema snapshot excluding tool tables, normalising AUTO_INCREMENT
snap(){ db=$1; mysqldump -h$H -uroot --no-data --skip-comments --skip-dump-date --routines --triggers --events --no-tablespaces --set-gtid-purged=OFF --ignore-table=$db.goose_db_version --ignore-table=$db.schema_migrations "$db" 2>/tmp/snap.err | sed -E 's/ AUTO_INCREMENT=[0-9]+//'; }
tables(){ qs $1 "SELECT table_name FROM information_schema.tables WHERE table_schema='$1' AND table_type='BASE TABLE' AND table_name NOT IN ('goose_db_version','schema_migrations') ORDER BY 1"; }
counts(){ db=$1; for t in $(tables $db); do printf '%s %s\n' $t "$(qs $db "SELECT COUNT(*) FROM \`$t\`")"; done; }
sums(){ db=$1; for t in $(tables $db); do qs $db "CHECKSUM TABLE \`$t\`"; done; }
state(){ db=$1; echo "--- state $db: tables: $(qs $db 'SHOW TABLES' | tr '\n' ' ')"; echo "orders columns: $(qs $db "SELECT GROUP_CONCAT(column_name ORDER BY ordinal_position) FROM information_schema.columns WHERE table_schema='$db' AND table_name='orders'")"; echo "orders rows:"; qs $db "SELECT id,sku,note FROM orders"; }
