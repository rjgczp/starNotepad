# 镜像推送使用教程

## 前提条件

- 已安装 Docker 并启动
- 有阿里云 ACR 仓库的访问权限

## 可用镜像目标

| 目标 | 说明 | 构建目录 |
|---|---|---|
| `gva-server` | 后端 API 服务 (Gin/Go) | `gin-vue-admin/server/` |
| `admin-web` | 管理后台 (Vue3) | `gin-vue-admin/web/` |
| `home-web` | 个人主页 (Next.js) | `personal-home-next/` |
| `bluemap` | Minecraft 地图服务 (Java JRE) | 不构建（只拉取基础镜像并打标签） |
| `all` | 以上全部 | — |

## 基本用法

```bash
./push-images.sh [选项] <tag> [目标...]
```

- **tag** — 镜像标签，如 `latest`、`v1.2.0`
- **目标** — 要构建/推送的镜像（可多个，空格分隔），不指定时默认为 `all`

## 常用命令示例

### 推送全部镜像

```bash
./push-images.sh latest
```

### 只推送一个镜像

```bash
# 只推送个人主页
./push-images.sh latest home-web

# 只推送管理后台
./push-images.sh latest admin-web
```

### 推送多个指定镜像

```bash
# 推送管理后台和个人主页
./push-images.sh latest admin-web home-web

# 推送后端和管理后台
./push-images.sh latest gva-server admin-web
```

### 只构建不推送（本地测试）

```bash
./push-images.sh --skip-push latest home-web
```

### 只推送已构建的镜像（不重新构建）

```bash
./push-images.sh --skip-build latest home-web
```

### 预览模式（不实际操作，只看将要做什么）

```bash
./push-images.sh --dry-run latest admin-web
```

## 环境变量

脚本支持通过环境变量覆盖默认配置：

```bash
# 指定自定义 tag
TAG=v1.2.0 ./push-images.sh home-web

# 指定自定义仓库
REGISTRY_REPO=my-registry.example.com/myproject/myimage ./push-images.sh latest

# 免交互登录
REGISTRY_USERNAME=你的用户名 \
REGISTRY_PASSWORD=你的密码 \
./push-images.sh latest

# 已登录过可以跳过登录
SKIP_LOGIN=1 ./push-images.sh latest
```

## 登录方式

### 方式一：交互式登录（默认）

```bash
./push-images.sh latest
# 运行后会提示输入用户名和密码
```

### 方式二：环境变量（CI/CD 推荐）

```bash
REGISTRY_USERNAME=你的ACR用户名 \
REGISTRY_PASSWORD=你的ACR密码 \
./push-images.sh latest
```

### 方式三：手动登录后跳过

```bash
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
SKIP_LOGIN=1 ./push-images.sh latest
```

## 输出示例

```
══════════════════════════════════════
  镜像推送配置
══════════════════════════════════════
  Tag:        latest
  Registry:   crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles
  Platform:   linux/amd64
  目标镜像:   admin-web home-web
  Dry-run:    否
  Skip-build: 否
  Skip-push:  否
──────────────────────────────────────

══════════════════════════════════════
[1/2] 处理: 管理后台 (Vue3)
  镜像: crpi-nxt6ib76b78qk7wc..../charles:admin-web-latest
[1/2.1] 构建镜像...
[INFO]  构建完成 ✓
[1/2.2] 推送镜像到仓库...
[INFO]  推送完成 ✓

══════════════════════════════════════
[2/2] 处理: 个人主页 (Next.js)
  镜像: crpi-nxt6ib76b78qk7wc..../charles:home-web-latest
[2/2.1] 构建镜像...
[INFO]  构建完成 ✓
[2/2.2] 推送镜像到仓库...
[INFO]  推送完成 ✓

══════════════════════════════════════
  全部完成!
══════════════════════════════════════
  成功: 2  失败: 0  总计: 2
```

## 常见场景

### 场景 1：修改了个人主页代码

```bash
cd personal-home-next
# ... 修改代码 ...
npm run build    # 本地验证

cd ..
SKIP_LOGIN=1 ./push-images.sh latest home-web
```

### 场景 2：修改了管理后台代码

```bash
cd gin-vue-admin/web
# ... 修改代码 ...
npm run build    # 本地验证

cd ../..
SKIP_LOGIN=1 ./push-images.sh latest admin-web
```

### 场景 3：修改了后端代码

```bash
cd gin-vue-admin/server
# ... 修改 Go 代码 ...

cd ../..
SKIP_LOGIN=1 ./push-images.sh latest gva-server
```

### 场景 4：发布新版本

```bash
# 用版本号标签推送所有镜像
./push-images.sh v1.5.0
```

## 服务器端更新

```bash
cd /opt/notepad

# 拉取指定服务的更新
docker compose pull home-web
docker compose up -d --force-recreate home-web

# 或拉取全部并重建
docker compose pull
docker compose up -d --force-recreate

# 如果配置了 watchtower，它会每 5 分钟自动检测并更新