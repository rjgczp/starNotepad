# 日常运维与故障排查

## 状态与日志

```bash
docker compose --env-file .env.production ps
docker compose --env-file .env.production logs --tail 200 gva-server
docker compose --env-file .env.production logs -f gva-web
docker compose --env-file .env.production stats
```

先看容器是否健康，再看入口 Nginx，最后看对应上游服务。不要一开始就删除容器或数据目录。

## 更新与回滚

更新：

```bash
./deploy-production.sh
```

固定版本部署建议保留上一个镜像标签。回滚时把 `.env.production` 中受影响服务改回上一个标签，然后：

```bash
docker compose --env-file .env.production up -d --no-deps --force-recreate 服务名
```

数据库结构发生不兼容变化时，仅回滚镜像可能不够；发布前应同时准备数据库备份和迁移回退方案。

## 备份

### MySQL 逻辑备份

```bash
docker compose --env-file .env.production exec -T mysql \
  sh -c 'exec mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --events --all-databases' \
  > mysql-all.sql
```

该命令让密码只在容器内展开，不会出现在宿主机命令行参数中。定期验证备份能在隔离环境恢复。

### 文件备份

至少备份：

```text
uploads/
bluemap/config/
bluemap/data/
bluemap/web/
bluemap/active-world/
.env.production
/home/ubuntu/opt/data/letsencrypt/
```

`.env.production` 和证书私钥应加密保存并限制访问。`logs/` 可按合规和排障需要设置保留周期，通常不作为业务恢复必需数据。

## 证书续期

```bash
./deploy/renew-production-cert.sh
openssl x509 -in /home/ubuntu/opt/data/ssl/xiaoyu.ski.pem -noout -dates
```

脚本在证书有效期不足 30 天，或证书缺少 `map.xiaoyu.ski` 时续期。建议通过 root 的 cron 或 systemd timer 定期执行并监控退出码。

## 常见故障

### Compose 提示 required variable

原因：`.env.production` 缺少必填变量或仍为空。

```bash
docker compose --env-file .env.production config --quiet
```

对照 [配置文档](./CONFIGURATION.md#生产必填变量) 补齐。不要用普通 `config` 输出到工单，因为它会展开秘密。

### 后端连接 MySQL 失败

容器内数据库地址必须是服务名 `mysql`，不是 `127.0.0.1`。生产 Compose 会注入 `DB_PATH=mysql`。

```bash
docker compose --env-file .env.production ps mysql
docker compose --env-file .env.production logs --tail 200 mysql
docker compose --env-file .env.production logs --tail 200 gva-server
```

如果更换了 `.env.production` 密码但复用了旧 `mysql_data/`，MySQL 内已有 root 密码不会自动改变。应使用旧密码登录后执行受控改密，不要直接删除数据目录。

### 站点 502

```bash
docker compose --env-file .env.production logs --tail 100 gva-web
docker compose --env-file .env.production ps
```

确认对应上游容器存在且端口与 `nginx.conf` 一致。更新单个容器后可执行：

```bash
docker compose --env-file .env.production restart gva-web
```

### API 404

当前后端全局前缀是 `/api`，Nginx 使用保留前缀的 `proxy_pass`。检查后端 Swagger 和路由注册，不要随意增加 rewrite 去掉 `/api`。

```bash
curl -I https://xiaoyu.ski/swagger/index.html
docker compose --env-file .env.production logs --tail 200 gva-server
```

### WebSocket 或情侣通话失败

1. 确认 `ai.xiaoyu.ski/api/duoCall/ws` 的 Nginx location 仍设置 Upgrade/Connection。
2. 查看后端日志是否成功建立 WebSocket。
3. 确认 `DUO_TURN_HOST`、用户和密码三项均非空。
4. 确认 `turn.xiaoyu.ski` 解析正确，安全组开放 TCP/UDP 3478 和 49152-49200。
5. 使用两个不同运营商网络测试；同一局域网成功不能证明 TURN 可用。

### 微信推送一直 pending

- 确认 `WX_TEST_ENABLED=true` 且后端已重建。
- 在管理后台检查 AppID、AppSecret、模板 ID 和两个 OpenID 的健康状态。
- 错误码 `40001`、`40014`、`42001` 通常与 token 失效有关，系统会刷新并重试一次。
- 详细绑定流程见 [微信测试号配置](./duo-wechat-test-account.md)。

### BlueMap 页面空白

检查挂载内容：

```bash
docker compose --env-file .env.production logs --tail 200 bluemap
ls -la bluemap/active-world bluemap/config bluemap/web
```

BlueMap 镜像不包含世界数据。`active-world/` 缺失或权限不正确时，容器即使运行也不会显示期望地图。

### ACR 拉取失败

```bash
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
docker compose --env-file .env.production pull gva-server
```

Watchtower 读取 `${HOME}/.docker/config.json`。若 Compose 由不同系统用户启动，确认该用户的 Docker 登录文件存在。

## 安全边界

- 不要执行 `docker compose down -v` 或删除 `mysql_data/` 来“修复”数据库，除非已有验证过的备份且明确要重建。
- 不要公开 3306、8888、8100 或各前端开发端口。
- 不要把 Compose 完整渲染结果、`.env.production` 或 TURN 密码发到公开渠道。
- 定期检查基础镜像和依赖安全更新，但先在测试环境验证。
