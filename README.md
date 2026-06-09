# 星记事 (Star Notepad)

“星记事”是一款基于 Flutter 的跨平台移动端笔记应用，搭配 Gin-Vue-Admin 后端，提供轻量、高效、支持 AI 辅助的个人笔记与日记管理工具。

## 技术栈

- **移动端**：Flutter（跨平台）
- **后端**：Go + Gin
- **管理后台**：Vue3（Gin-Vue-Admin）
- **个人主页**：Next.js
- **数据库**：MySQL 8.0
- **地图服务**：BlueMap（Minecraft）

## 仓库结构

```text
notepad/
├── startNotepad_flutter/      # Flutter 移动端 App
├── gin-vue-admin/             # 后端 (server) + 管理后台 (web)
├── personal-home-next/        # Next.js 个人主页
├── bluemap/                   # BlueMap 地图服务运行目录
├── docker-compose.yml         # 生产编排
├── docker-compose.dev.yml     # 本地开发编排
├── nginx.conf                 # 反向代理配置
├── push-images.sh             # 镜像构建推送脚本
├── starNotepad.sql            # 数据库初始化脚本
└── docs/                      # 部署与排查文档
```

## 快速上手

本地开发：

```bash
docker compose -f docker-compose.dev.yml up -d
```

- 个人主页：http://localhost:3000
- 管理后台：http://localhost:5173
- 后端 API：http://localhost:8888
- BlueMap：http://localhost:8100

完整部署流程见 [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)，常见问题见 [docs/TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)。

## 版权声明

本项目代码及文档遵循 [MIT 许可证](https://opensource.org/license/MIT)。

- 本项目为开源项目，用于技术交流与个人学习。
- 后台系统基于 Gin-Vue-Admin 开源框架开发，核心业务模块由本人自主研发。
- 开发者不承担因使用本项目导致的任何数据丢失、服务器损坏或法律纠纷风险。
- 商业使用请确保符合相关法律法规，并保留原作者版权声明。

## 反馈

有 Bug 或改进建议，欢迎提交 Issue。
