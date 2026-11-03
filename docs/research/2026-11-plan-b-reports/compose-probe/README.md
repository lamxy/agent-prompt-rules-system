# Compose 事故取证与备份还原实测（2026-11-03）

第三轮第 35、36 条写入前的实测。环境：本机 Docker Compose，临时项目 `cprobe`、`cprobe2`、`bprobe`。

## 事故取证与处置（第 35 条，`incident-compose.yaml`、`scale-compose.yaml`）

| 操作 | 结果 |
|---|---|
| `docker compose restart app` | 容器保留，`logs` 同时有重启前后两行 |
| 改 `APP_IMAGE` 后 `docker compose up -d --no-deps app` | 容器重建，`logs` 只剩新容器一行，**旧日志丢失** |
| `docker compose logs --timestamps --since 2h app > 文件` | 成功导出 |
| `docker inspect --format '{{.State.Status}} oom={{.State.OOMKilled}} restarts={{.RestartCount}} exit={{.State.ExitCode}}'` | 输出 `running oom=false restarts=0 exit=0` |
| `docker compose ps -a app --format '{{.Service}} {{.Image}} {{.Status}}'` | 成功 |
| `docker compose up -d --no-deps --scale app=2 app` | 成功，出现 `app-2` |
| 设了 `container_name` 时 `--scale app=2` | 只警告「Remove the custom name to scale the service」，没有扩容 |
| 固定主机端口时 `--scale web=2` | 第二个容器报「port is already allocated」 |

## 备份还原（第 36 条，`backup-compose.yaml`、`backup-run.sh`）

源库：`postgres:17-alpine`，哨兵表 200,001 行，`count + md5(string_agg(note ORDER BY id))` = `200001 95c323f5c549a9efe4e9c3d3dfd987d7`。

| 情境 | 结果 |
|---|---|
| A：`pg_dump -Fc`（运行中）→ `--network none` 临时容器 `pg_restore --no-owner` | 退出码 0，dump 4.4MB，各约 0 秒；还原后摘要相同 |
| B：停服务 → busybox `tar czf`（卷只读挂载）→ 解到新卷 → 临时容器启动 | 摘要相同；数据目录属主 uid 70 保留 |
| B2：Beszel 卷冷备份 → 新卷启动 | 卷内有 `data.db`、`auxiliary.db`、`id_ed25519`（私钥）；`/api/health` 返回 200 |

未测：Uptime Kuma 卷、备份失败告警（Kuma Push）、离机传输、加密、数据库大版本间还原、大数据量耗时。

## 残留

清理命令被权限规则拒绝，需手动执行（见 `docs/handoff/HANDOFF.md`）。
