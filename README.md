# OmniProject

OmniProject 是一套部署在同一网关后的个人应用集合，包含星记事移动端、Go 后端、管理后台、个人主页、博客、情侣空间与 BlueMap。生产环境使用 Docker Compose 编排，由 Nginx 统一提供 HTTPS 入口。

## 公网入口

以下地址已于 2026-07-29 实测返回 HTTP 200，均解析到公网 IP `82.157.105.7`。

| 应用 | 公网地址 | 说明 |
| --- | --- | --- |
| 个人主页 | <https://xiaoyu.ski> | 主入口 |
| 个人主页（别名） | <https://home.xiaoyu.ski> | 与主入口指向同一服务 |
| 博客 | <https://blog.xiaoyu.ski> | 独立 Next.js 博客 |
| 情侣空间 | <https://ai.xiaoyu.ski> | 双人主页、相册、每日回信与实时通话 |
| 管理后台 | <https://ht.xiaoyu.ski> | Gin-Vue-Admin 管理端 |
| Minecraft 地图 | <https://map.xiaoyu.ski> | BlueMap |

后端 API 统一经各站点的 `/api/` 转发，不需要也不应直接向公网开放 `8888`。TURN 服务使用 `turn.xiaoyu.ski:3478`，它不是浏览器页面。

## 项目组成

| 目录/文件 | 技术 | 用途 |
| --- | --- | --- |
| `startNotepad_flutter/` | Flutter | 星记事移动端 |
| `gin-vue-admin/server/` | Go、Gin、GORM | 共用 API、鉴权与业务后端 |
| `gin-vue-admin/web/` | Vue 3、Vite | 管理后台 |
| `personal-home-next/` | Next.js | 个人主页 |
| `blog-frontend/` | Next.js | 博客站点 |
| `duo-call-web/` | React、Vite、WebRTC | 情侣空间 |
| `bluemap/` | BlueMap、Java | Minecraft 地图 |
| `docker-compose.yml` | Docker Compose | 生产编排 |
| `docker-compose.dev.yml` | Docker Compose | 本地开发编排 |
| `nginx.conf` | Nginx | HTTPS 与反向代理 |
| `deploy/` | Shell、Coturn | 环境准备、证书和 TURN 配置 |
| `openspec/` | OpenSpec | 功能变更设计与实施记录 |

## 快速开始

先准备环境变量：

```bash
cp .env.example .env.local
```

至少将 `.env.local` 中的 `MYSQL_ROOT_PASSWORD`、`GVA_JWT_SIGNING_KEY`、`DUO_CALL_JWT_SECRET` 和 `DUO_CALL_KEY_ENCRYPTION_KEY` 换成非示例值，然后启动：

```bash
docker compose --env-file .env.local -f docker-compose.dev.yml up -d
docker compose --env-file .env.local -f docker-compose.dev.yml ps
```

本地入口：

| 服务 | 地址 |
| --- | --- |
| 个人主页 | <http://localhost:3000> |
| 博客 | <http://localhost:3001> |
| 情侣空间 | <http://localhost:3002> |
| 管理后台 | <http://localhost:5173> |
| 后端 API | <http://localhost:8888/api/> |
| BlueMap | <http://localhost:8100> |
| MySQL | `127.0.0.1:3306` |

停止开发环境：

```bash
docker compose --env-file .env.local -f docker-compose.dev.yml down
```

## 文档

- [文档索引](./docs/README.md)
- [系统架构与服务边界](./docs/ARCHITECTURE.md)
- [本地开发](./docs/DEVELOPMENT.md)
- [配置文件与环境变量](./docs/CONFIGURATION.md)
- [生产部署与公网接入](./docs/DEPLOYMENT.md)
- [日常运维与故障排查](./docs/OPERATIONS.md)
- [仓库冗余与安全检查](./docs/REPOSITORY_AUDIT.md)
- [微信测试号配置](./docs/duo-wechat-test-account.md)

各前端和移动端目录内的 README 只说明该组件如何单独开发；跨服务配置与生产发布一律以根目录 `docs/` 为准。

## 常用命令

```bash
# 校验生产编排
docker compose --env-file .env.production -f docker-compose.yml config --quiet

# 查看生产状态
docker compose --env-file .env.production -f docker-compose.yml ps

# 查看某个服务日志
docker compose --env-file .env.production -f docker-compose.yml logs -f gva-server

# 构建并推送全部业务镜像
./push-images.sh latest

# 拉取镜像并滚动更新
./deploy-production.sh
```

生产部署前请完整阅读 [生产部署文档](./docs/DEPLOYMENT.md)，尤其是 DNS、TLS、TURN 端口、持久化目录和备份章节。
