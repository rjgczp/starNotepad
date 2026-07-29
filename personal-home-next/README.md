# 个人主页

OmniProject 的个人主页，基于 Next.js App Router。生产入口为 <https://xiaoyu.ski>，`home.xiaoyu.ski` 是同一服务的别名。

## 开发

```bash
npm ci
BACKEND_URL=http://127.0.0.1:8888 npm run dev
```

访问 <http://localhost:3000>。

| 变量 | 用途 | 默认值 |
| --- | --- | --- |
| `BACKEND_URL` | 服务端重写到 Gin API 的地址 | `http://127.0.0.1:8888` |
| `BLOG_PROFILE_API_URL` | 个人资料服务端接口 | Compose 中指向 `gva-server` |
| `MAIN_IMAGE_API_URL` | 主图服务端接口 | Compose 中指向 `gva-server` |

浏览器始终请求同源 `/api/*`；生产由 Next.js/Nginx 转到后端，不要把容器内地址暴露给浏览器。

## 检查与构建

```bash
npm run lint
npm run build
npm start
```

生产镜像由根目录 `push-images.sh` 构建，服务名为 `home-web`。整套配置、部署和公网路由见 [项目文档](../docs/README.md)。
