# 本地开发

## 环境要求

- Docker Desktop 或 Docker Engine + Compose v2
- 单独开发组件时还需 Go 1.24、Node.js 20/22、Flutter 3（Dart 3.7）中的对应工具
- 至少预留约 4 GB 内存；同时运行 Next.js、Go、MySQL、BlueMap 时建议更多

## 用 Compose 启动整套环境

```bash
cp .env.example .env.local
```

编辑 `.env.local`，换掉所有 `change_me` 和 `replace_with_random_value`。本地不测试 WebRTC 时，TURN 相关变量仍需提供非空占位值，因为生产编排和部分后端启动检查会读取它们。

```bash
docker compose --env-file .env.local -f docker-compose.dev.yml config --quiet
docker compose --env-file .env.local -f docker-compose.dev.yml up -d
docker compose --env-file .env.local -f docker-compose.dev.yml ps
```

默认端口：

| 组件 | 本地地址 | 覆盖变量 |
| --- | --- | --- |
| MySQL | `127.0.0.1:3306` | `MYSQL_PORT` |
| 后端 | <http://localhost:8888> | `GVA_SERVER_PORT` |
| 个人主页 | <http://localhost:3000> | `HOME_WEB_PORT` |
| 博客 | <http://localhost:3001> | `BLOG_FRONTEND_PORT` |
| 情侣空间 | <http://localhost:3002> | `DUO_CALL_WEB_PORT` |
| 管理后台 | <http://localhost:5173> | `ADMIN_WEB_DEV_PORT` |
| BlueMap | <http://localhost:8100> | `BLUEMAP_PORT` |

常用调试命令：

```bash
docker compose --env-file .env.local -f docker-compose.dev.yml logs -f gva-server
docker compose --env-file .env.local -f docker-compose.dev.yml restart duo-call-web
docker compose --env-file .env.local -f docker-compose.dev.yml down
```

本地 Compose 包含写死的 macOS Go 模块缓存路径：

```text
/Users/sansea/go/pkg/mod
/Users/sansea/Library/Caches/go-build
```

在其他电脑或 Linux 上运行前，应删除这两个绑定挂载，或改成命名卷。当前文件末尾已声明 `gva-go-mod-cache` 和 `gva-go-build-cache`，但尚未实际使用。

## 单独运行组件

### Go 后端

先保证 MySQL 可用，然后：

```bash
cd gin-vue-admin/server
DB_PATH=127.0.0.1 \
MYSQL_ROOT_PASSWORD=你的本地密码 \
GVA_JWT_SIGNING_KEY=本地随机值 \
go run . -c config.yaml
```

Docker 开发环境使用 `config.docker.yaml`；宿主机直接运行通常使用 `config.yaml` 并通过 `DB_PATH` 覆盖数据库地址。

### 管理后台

```bash
cd gin-vue-admin/web
npm ci
npm run dev
```

管理后台的 Vite 代理读取 `.env.development`。在宿主机直接运行时，将 `VITE_BASE_PATH` 设为 `http://127.0.0.1`；在 Compose 容器内使用 `http://gva-server`。

### 个人主页

```bash
cd personal-home-next
npm ci
BACKEND_URL=http://127.0.0.1:8888 npm run dev
```

### 博客

```bash
cd blog-frontend
npm ci
BACKEND_URL=http://127.0.0.1:8888 npm run dev -- --port 3001
```

### 情侣空间

```bash
cd duo-call-web
cp .env.example .env.local
npm ci
DUO_API_PROXY=http://127.0.0.1:8888 npm run dev
```

浏览器请求仍使用同源 `/api`；Vite 将其代理到 `DUO_API_PROXY`。

### Flutter App

Android 模拟器默认访问 `http://10.0.2.2:8888`。真机或生产构建必须显式提供可访问的 HTTPS 地址：

```bash
cd startNotepad_flutter
flutter pub get
flutter run --dart-define=BASE_URL=https://xiaoyu.ski
```

如需启用邮件验证码模式，再添加：

```text
--dart-define=EMAIL_VERIFY_CODE_MODE=true
```

## 提交前检查

```bash
cd gin-vue-admin/server && go test ./...
cd gin-vue-admin/web && npm run build
cd personal-home-next && npm run build
cd blog-frontend && npm run build
cd duo-call-web && npm run lint && npm test && npm run build
cd startNotepad_flutter && flutter analyze && flutter test
```

根据本次改动选择相关检查即可，不必每次构建所有组件。
