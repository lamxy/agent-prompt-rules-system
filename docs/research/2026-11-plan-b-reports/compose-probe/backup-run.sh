set -u
export POSTGRES_PASSWORD=probe-$(date +%s)
P="docker compose -p bprobe"
q(){ docker exec -i "$1" psql -U postgres -d glitchtip -tAc "$2"; }
waitpg(){ for i in $(seq 1 60); do docker exec "$1" pg_isready -U postgres -d glitchtip >/dev/null 2>&1 && return 0; sleep 1; done; echo "pg not ready $1"; }
$P up -d --wait 2>&1 | tail -1
q bprobe-postgres-1 "CREATE TABLE sentinel(id int primary key, note text); INSERT INTO sentinel SELECT g, md5(g::text) FROM generate_series(1,200000) g; INSERT INTO sentinel VALUES (-1,'MARKER');" 
SRC=$(q bprobe-postgres-1 "SELECT count(*)||' '||md5(string_agg(note,',' ORDER BY id)) FROM sentinel")
echo "src: $SRC"
echo "== A logical pg_dump -> isolated restore"
t0=$(date +%s); $P exec -T postgres pg_dump -U postgres -Fc glitchtip > glitchtip.dump; echo "dump exit=$? size=$(wc -c < glitchtip.dump) secs=$(( $(date +%s)-t0 ))"
docker run -d --name bprobe-rA --network none -e POSTGRES_PASSWORD=x -e POSTGRES_DB=glitchtip postgres:17-alpine >/dev/null; waitpg bprobe-rA; sleep 2; waitpg bprobe-rA
t0=$(date +%s); docker exec -i bprobe-rA pg_restore -U postgres -d glitchtip --no-owner < glitchtip.dump; echo "restore exit=$? secs=$(( $(date +%s)-t0 ))"
echo "A: $(q bprobe-rA "SELECT count(*)||' '||md5(string_agg(note,',' ORDER BY id)) FROM sentinel")"
echo "== B cold volume tar"
$P stop postgres beszel 2>&1 | tail -1
docker run --rm -v bprobe_pg-data:/data:ro -v "$PWD":/backup busybox:1.36 tar czf /backup/pg-data.tgz -C /data . ; echo "tar exit=$?"
docker run --rm -v bprobe_beszel-data:/data:ro -v "$PWD":/backup busybox:1.36 tar czf /backup/beszel-data.tgz -C /data . ; echo "tar beszel exit=$?"
$P start postgres beszel 2>&1 | tail -1
docker volume create bprobe-rB >/dev/null
docker run --rm -v bprobe-rB:/data -v "$PWD":/backup:ro busybox:1.36 tar xzf /backup/pg-data.tgz -C /data; echo "untar exit=$?"
docker run -d --name bprobe-rB --network none -v bprobe-rB:/var/lib/postgresql/data -e POSTGRES_PASSWORD=x postgres:17-alpine >/dev/null; waitpg bprobe-rB
echo "B: $(q bprobe-rB "SELECT count(*)||' '||md5(string_agg(note,',' ORDER BY id)) FROM sentinel")"
docker exec bprobe-rB ls -ln /var/lib/postgresql/data | sed -n 2,3p
echo "== B2 beszel"
tar tzf beszel-data.tgz | head
docker volume create bprobe-rC >/dev/null
docker run --rm -v bprobe-rC:/data -v "$PWD":/backup:ro busybox:1.36 tar xzf /backup/beszel-data.tgz -C /data
docker network create bprobe-rnet >/dev/null
docker run -d --name bprobe-rC --network bprobe-rnet -v bprobe-rC:/beszel_data henrygd/beszel:0.21.1 >/dev/null; sleep 4
docker run --rm --network bprobe-rnet busybox:1.36 wget -qO- http://bprobe-rC:8090/api/health; echo " health exit=$?"
docker logs bprobe-rC 2>&1 | tail -3
