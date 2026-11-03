# 备份与还原（Docker Compose 卷）

适用于单机 Docker Compose 部署的数据卷，以 `assets/observability/compose.monitor.yml` 为例。MongoDB 见 `mongodb.md`「备份与恢复」，Redis 持久化见 `redis.md`。

下文「实测」指 2026-11-03 在临时 Compose 项目中用 `postgres:17-alpine`（20 万行哨兵表）与 `henrygd/beszel:0.21.1` 跑通的流程；数据量小，耗时只有相对意义。

## 1. 逐卷分类

先列出 compose 中的每个卷，逐个写明「必须备份」或「可重建」及重建方式，只备份不可重建的卷。

| 卷 | 内容 | 分类 |
|---|---|---|
| `pg-data` | GlitchTip 的错误事件、项目、账号 | 必须备份 |
| `beszel-data` | `data.db`、`auxiliary.db`，以及 hub 私钥 `id_ed25519`（实测） | 必须备份；备份文件按秘密保管 |
| `kuma-data` | Uptime Kuma 的数据目录 | 必须备份；其内容与还原后能否正常运行未实测，首次演练时确认 |

容器日志（`local` 驱动）不在卷里，容器重建即丢失；排障需要的日志在重建前导出（见 `incident-response-commander` 的取证步骤）。

## 2. 备份

数据库用逻辑备份，不停机（实测）：

```bash
docker compose exec -T postgres pg_dump -U postgres -Fc glitchtip > glitchtip-$(date -u +%Y%m%dT%H%M%SZ).dump
```

其他卷用冷备份：先停用这个卷的服务，以只读方式挂载打包，再启动（实测）。不在服务运行时直接复制卷，文件可能处于写入中途。

```bash
docker compose stop beszel
docker run --rm -v <项目名>_beszel-data:/data:ro -v "$PWD":/backup busybox:1.36 \
  tar czf /backup/beszel-data-$(date -u +%Y%m%dT%H%M%SZ).tgz -C /data .
docker compose start beszel
```

卷的实际名称是 `<项目名>_<卷名>`，用 `docker volume ls` 确认。

## 3. 存放

- 备份传到这台主机以外的位置；与主机放在一起，主机丢失时备份一起丢失。
- 备份文件含业务数据与私钥：加密存放，限制读取权限，不入库。
- 加密用的密码或密钥不与备份、`.env` 放在同一处，否则一处泄露全部可读；密钥丢失则所有备份不可读，要另行托管。
- 保留天数按业务决定，并写进部署说明。

## 4. 还原演练

只有还原成功才算备份可用，备份命令的退出码不能证明这一点。新建备份方案、更换备份工具或升级数据库大版本后都做一次，并定期重复。

1. 还原到隔离的临时容器，不碰线上卷：

   ```bash
   docker run -d --name restore-check --network none \
     -e POSTGRES_PASSWORD=<临时值> -e POSTGRES_DB=glitchtip postgres:17-alpine
   docker exec restore-check pg_isready -U postgres -d glitchtip   # 重试到就绪
   docker exec -i restore-check pg_restore -U postgres -d glitchtip --no-owner < glitchtip-<时间>.dump
   ```

   冷备份的卷先解到新卷，再用新卷启动临时容器：

   ```bash
   docker volume create restore-check-vol
   docker run --rm -v restore-check-vol:/data -v "$PWD":/backup:ro busybox:1.36 \
     tar xzf /backup/<卷备份>.tgz -C /data
   ```

   临时容器用与线上相同的镜像版本。实测 busybox `tar` 解包后保留了 Postgres 数据目录的属主（uid 70），容器可直接启动。

2. 独立验证数据，不只看服务能否启动：对关键表比对行数与内容摘要，例如 `SELECT count(*), md5(string_agg(<列>, ',' ORDER BY id)) FROM <表>`，与备份时在源库记下的值比较。Web 服务可访问健康检查端点（实测 Beszel 用备份卷启动后 `/api/health` 返回 200），并登录确认配置还在。
3. 记录备份与还原的实际耗时、文件大小，写进部署说明，作为恢复时间的依据。
4. 演练结束删除临时容器与卷。

真实恢复时同样先还原到新卷或新容器并验证，再切换服务，不直接覆盖线上卷。
