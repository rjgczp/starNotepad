# 情侣空间前端

基于 React、Vite 和 WebRTC 的双人空间，包含个人状态、记忆树主页、相册、每日回信、聊天和音视频通话。生产入口为 <https://ai.xiaoyu.ski>。

## 开发

```bash
cp .env.example .env.local
npm ci
DUO_API_PROXY=http://127.0.0.1:8888 npm run dev
```

访问 <http://localhost:3002>。

| 变量 | 用途 |
| --- | --- |
| `VITE_DUO_API_URL` | 浏览器 API 前缀，通常保持 `/api` |
| `DUO_API_PROXY` | Vite 开发服务器代理目标 |
| `VITE_DUO_ICE_SERVERS` | 本地 ICE 兜底 JSON；生产由后端返回 |

真实 TURN 用户名和密码由已认证的后端启动接口下发，不要写入前端 `.env` 或镜像。

## 检查与构建

```bash
npm run lint
npm test
npm run build
npm run preview
```

生产镜像使用 Nginx 提供 `dist/` 静态文件，根 Compose 服务名为 `duo-call-web`。WebSocket、TURN、微信与部署配置见父项目 [文档索引](../docs/README.md)。
