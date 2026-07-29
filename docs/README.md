# 项目文档索引

这套文档按“先认识项目，再开发、配置、部署和运维”的顺序组织。第一次接手建议依次阅读前五篇。

| 文档 | 适用场景 |
| --- | --- |
| [系统架构与服务边界](./ARCHITECTURE.md) | 了解各组件职责、端口和请求流向 |
| [本地开发](./DEVELOPMENT.md) | 在本机启动整套环境或单独调试组件 |
| [配置文件与环境变量](./CONFIGURATION.md) | 修改数据库、镜像、微信、TURN、Nginx 等配置 |
| [生产部署与公网接入](./DEPLOYMENT.md) | 新服务器部署、DNS、TLS、发布镜像 |
| [日常运维与故障排查](./OPERATIONS.md) | 更新、日志、备份、恢复和常见故障 |
| [仓库冗余与安全检查](./REPOSITORY_AUDIT.md) | 了解哪些文件应保留、忽略或后续清理 |
| [微信测试号配置](./duo-wechat-test-account.md) | 配置情侣空间微信提醒 |

组件文档：

- [个人主页](../personal-home-next/README.md)
- [博客前端](../blog-frontend/README.md)
- [情侣空间前端](../duo-call-web/README.md)
- [星记事 Flutter App](../startNotepad_flutter/README.md)
- [Gin-Vue-Admin 上游说明](../gin-vue-admin/README.md)
- [后端说明](../gin-vue-admin/server/README.md)

## 文档维护约定

- 根目录 `README.md` 只保留项目入口、快速开始和文档导航。
- 跨服务说明统一放在 `docs/`，不要再放进 `logs/` 等运行时目录。
- 组件目录 README 只说明该组件的用途、开发命令和组件专属配置。
- 命令中的密码、JWT 密钥、微信 AppSecret、TURN 密码只能写变量名或占位值。
- 公网域名、端口、镜像名称变化时，同时检查 `nginx.conf`、`docker-compose.yml`、`.env.example` 和本目录文档。
- `openspec/` 是设计与变更记录，不等同于当前运行手册；当前行为以代码和本目录文档为准。
