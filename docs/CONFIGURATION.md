# 配置文件与环境变量

## 配置加载关系

| 文件 | 是否提交 Git | 用途 |
| --- | --- | --- |
| `.env.example` | 是 | 根环境变量模板，不放真实密钥 |
| `.env.local` | 否 | 本地 Compose 配置 |
| `.env.production` | 否 | 生产 Compose 配置与密钥 |
| `docker-compose.dev.yml` | 是 | 源码挂载、热更新、开发端口 |
| `docker-compose.yml` | 是 | 生产镜像、Nginx、Coturn、Watchtower |
| `gin-vue-admin/server/config.yaml` | 是 | 生产后端基础配置 |
| `gin-vue-admin/server/config.docker.yaml` | 是 | 本地容器后端基础配置 |
| `gin-vue-admin/web/.env.production.example` | 是 | 管理后台生产构建模板 |
| `gin-vue-admin/web/.env.production` | 否 | 管理后台实际生产构建变量 |
| `nginx.conf` | 是 | 域名、TLS、路由与缓存 |
| `deploy/coturn/turnserver.conf.example` | 是 | TURN 固定参数 |
| `duo-call-web/.env.example` | 是 | Duo 前端本地开发示例 |

环境变量由 Compose 注入后端，后端的 Viper 绑定会覆盖 YAML 中对应的敏感值。因此真实密码只写 `.env.local` 或 `.env.production`，不要直接写入已提交的 `config*.yaml`。

## 生产必填变量

| 变量 | 用途 | 建议 |
| --- | --- | --- |
| `MYSQL_ROOT_PASSWORD` | MySQL root 与后端数据库连接 | 随机长密码；备份时一并保管 |
| `GVA_JWT_SIGNING_KEY` | 管理后台 JWT 签名 | 至少 32 字节随机值 |
| `DUO_CALL_JWT_SECRET` | 情侣空间令牌签名 | 与 GVA JWT 使用不同随机值 |
| `DUO_CALL_KEY_ENCRYPTION_KEY` | 情侣身份密钥/OpenID 加密 | 必须长期备份，丢失后需重新绑定 |
| `DUO_TURN_USERNAME` | TURN 用户名 | 可读标识即可 |
| `DUO_TURN_PASSWORD` | TURN 凭据 | 随机长密码 |
| `TURN_EXTERNAL_IP` | Coturn 公网 IP | 当前为 `82.157.105.7` |

`docker-compose.yml` 使用 `${变量:?错误信息}` 强制检查上述变量。推荐生成方式：

```bash
openssl rand -hex 32
```

可以先运行：

```bash
cp .env.example .env.production
./deploy/prepare-production-env.sh
```

脚本会生成 JWT、Duo 加密和 TURN 密钥，但不会替换 `MYSQL_ROOT_PASSWORD=change_me`，数据库密码必须手工修改。

## 镜像变量

| 变量 | 默认镜像标签 |
| --- | --- |
| `GVA_SERVER_IMAGE` | `gva-server-latest` |
| `ADMIN_WEB_IMAGE` | `admin-web-latest` |
| `HOME_WEB_IMAGE` | `home-web-latest` |
| `BLOG_FRONTEND_IMAGE` | `blog-frontend-latest` |
| `DUO_CALL_WEB_IMAGE` | `duo-call-web-latest` |
| `BLUEMAP_IMAGE` | `bluemap-jre-25` |
| `MYSQL_IMAGE` | `mysql:8.0.45` |

业务镜像默认位于：

```text
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles
```

构建管理后台镜像前，确认实际生产文件存在：

```bash
cp gin-vue-admin/web/.env.production.example gin-vue-admin/web/.env.production
```

该文件会被 Vite 在构建阶段读取，但因 `.gitignore` 规则不会提交；可提交的默认值只维护在 `.env.production.example`。

发布固定版本时，不要只改变本地 `TAG`；还要把 `.env.production` 中对应镜像值更新成相同版本。

## 端口变量

生产：

| 变量 | 默认值 | 说明 |
| --- | ---: | --- |
| `WEB_PORT` | 80 | Nginx HTTP，自动跳 HTTPS |
| `HTTPS_PORT` | 443 | Nginx HTTPS |

开发：

| 变量 | 默认值 |
| --- | ---: |
| `MYSQL_PORT` | 3306 |
| `GVA_SERVER_PORT` | 8888 |
| `HOME_WEB_PORT` | 3000 |
| `BLOG_FRONTEND_PORT` | 3001 |
| `DUO_CALL_WEB_PORT` | 3002 |
| `ADMIN_WEB_DEV_PORT` | 5173 |
| `BLUEMAP_PORT` | 8100 |

生产 Compose 中的 BlueMap 只使用 `expose: 8100`，所以根模板里的 `BLUEMAP_PORT` 只对开发编排有效。

## 微信测试号

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `WX_TEST_ENABLED` | `false` | 是否启动外发 worker |
| `WX_TEST_APPID` | 空 | 测试号 AppID |
| `WX_TEST_SECRET` | 空 | 测试号 AppSecret，敏感 |
| `WX_TEST_TEMPLATE_ID` | 空 | 消息模板 ID |
| `DUO_PUBLIC_BASE_URL` | 空 | 推送点击入口，生产应为 `https://ai.xiaoyu.ski` |

完整步骤见 [微信测试号配置](./duo-wechat-test-account.md)。

## WebRTC 与 TURN

| 变量 | 当前生产值/用途 |
| --- | --- |
| `DUO_TURN_HOST` | `turn.xiaoyu.ski` |
| `DUO_TURN_USERNAME` | 后端返回给已认证的 Duo 用户 |
| `DUO_TURN_PASSWORD` | 后端返回给已认证的 Duo 用户，禁止写入前端仓库 |
| `TURN_EXTERNAL_IP` | `82.157.105.7` |

生产前端从后端 `bootstrap` 响应获取 ICE servers。`duo-call-web/.env.example` 中的 `VITE_DUO_ICE_SERVERS` 只是本地兜底，不应在生产镜像里硬编码真实 TURN 密码。

## 后端 YAML

需要经常关注的配置段：

- `system`：端口、路由前缀、数据库类型、自动迁移。
- `mysql`：数据库地址、库名和连接池。
- `jwt`：令牌有效期；签名密钥由环境变量覆盖。
- `local`：上传文件的逻辑路径和落盘路径。
- `zap`：日志等级、目录与保留策略。
- `duo-ritual`：每日问题时间、微信字段、重试与聚合节奏。

OSS、Redis、Mongo、MSSQL、PostgreSQL 等大量段落来自 Gin-Vue-Admin 上游模板。当前 `system.oss-type=local`、`use-redis=false`、`use-mongo=false`，未启用的示例值不会参与当前运行，但删减前需确认后台“系统配置”页和配置结构体是否仍依赖它们。

## Nginx 与证书

`nginx.conf` 中的域名和证书路径目前是项目专用硬编码：

```text
/home/ubuntu/opt/data/ssl/xiaoyu.ski.pem
/home/ubuntu/opt/data/ssl/xiaoyu.ski.key
```

如果换域名或服务器用户，需要同步修改：

1. `nginx.conf` 的 `server_name`。
2. `docker-compose.yml` 的证书挂载。
3. `deploy/renew-production-cert.sh` 的域名和宿主机路径。
4. `.env.production` 的 `DUO_PUBLIC_BASE_URL`、`DUO_TURN_HOST` 和 `TURN_EXTERNAL_IP`。
5. DNS 与安全组。

## 密钥规则

- 不提交 `.env`、`.env.local`、`.env.production`、证书私钥或 Docker 登录凭据。
- 不在 issue、日志和截图中展示密钥。
- `DUO_CALL_KEY_ENCRYPTION_KEY` 轮换前先停止微信 worker，并迁移或重新绑定加密数据。
- 修改数据库密码后，重建 MySQL 容器不会自动改变已有数据目录中的 root 密码；需要在 MySQL 内执行改密或进行受控迁移。
