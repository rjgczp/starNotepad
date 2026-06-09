# 部署指南

本项目使用 Docker Compose 编排，支持「本地开发」和「云服务器生产」两种模式。

## 配置文件总览

| 文件 | 用途 |
| --- | --- |
| `docker-compose.yml` | 生产编排，使用阿里云 ACR 预构建镜像 |
| `docker-compose.dev.yml` | 本地开发编排，挂载源码、热重载 |
| `.env.production` | 生产环境变量（含密码，不进 git） |
| `.env.example` | 环境变量模板，复制后改名使用 |
| `nginx.conf` | 反向代理配置 |
| `push-images.sh` | 构建并推送镜像到阿里云 ACR |
| `starNotepad.sql` | 数据库初始化脚本 |

## 服务构成

| 服务 | 说明 | 端口 |
| --- | --- | --- |
| `mysql` | MySQL 8.0 数据库 | 3306 |
| `gva-server` | Gin 后端 API | 8888 |
| `home-web` | Next.js 个人主页 | 3000 |
| `admin-web` | Vue3 管理后台 | 5173(dev) |
| `gva-web` | Nginx 反向代理 | 80 |
| `bluemap` | Minecraft 地图服务 | 8100 |
| `watchtower` | 自动更新容器（仅生产） | - |

---

## 一、本地开发

源码挂载进容器，改动即时生效。

```bash
# 启动
docker compose -f docker-compose.dev.yml up -d

# 查看状态
docker compose -f docker-compose.dev.yml ps

# 查看日志
docker compose -f docker-compose.dev.yml logs -f

# 重新构建并启动
docker compose -f docker-compose.dev.yml up -d --build

# 停止
docker compose -f docker-compose.dev.yml down
```

本地访问地址：

- 个人主页：http://localhost:3000
- 管理后台（开发页）：http://localhost:5173
- 后端 API：http://localhost:8888
- BlueMap：http://localhost:8100

> 本地后端读取 `gin-vue-admin/server/config.docker.yaml`，数据库连本地 MySQL 容器。
> 端口可通过环境变量覆盖（`MYSQL_PORT`、`GVA_SERVER_PORT`、`HOME_WEB_PORT`、`ADMIN_WEB_DEV_PORT`、`BLUEMAP_PORT`）。

---

## 二、云服务器生产部署

生产环境从阿里云 ACR 拉取预构建镜像，不需要上传源码。

### 1. 准备服务器

```bash
# 安装 Docker（含 Compose 插件）
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# 重新登录使分组生效
docker compose version
```

### 2. 创建目录结构

```bash
sudo mkdir -p /opt/notepad && sudo chown -R $USER:$USER /opt/notepad
cd /opt/notepad
mkdir -p uploads logs mysql_data gin-vue-admin/server
mkdir -p bluemap/config bluemap/data bluemap/web bluemap/active-world
```

推荐的运行目录结构：

```text
/opt/notepad/
├── docker-compose.yml
├── .env.production
├── nginx.conf
├── starNotepad.sql
├── gin-vue-admin/server/config.yaml
├── bluemap/{cli.jar,config,data,web,active-world}
├── uploads/        # 后端上传文件
├── logs/           # 后端日志
└── mysql_data/     # MySQL 数据
```

### 3. 上传必要文件

云服务器只跑容器，源码和构建产物不用上传。需要的文件：

```bash
scp docker-compose.yml .env.production nginx.conf starNotepad.sql \
    user@服务器IP:/opt/notepad/
scp gin-vue-admin/server/config.yaml \
    user@服务器IP:/opt/notepad/gin-vue-admin/server/config.yaml
scp -r bluemap/cli.jar bluemap/config bluemap/data bluemap/web \
    user@服务器IP:/opt/notepad/bluemap/
```

> BlueMap 镜像只是 Java 运行环境，真正的程序、配置、webroot 和世界目录都来自挂载的本地目录。

### 4. 拉取镜像并启动

```bash
cd /opt/notepad

# 登录阿里云 ACR
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com

# 拉取并启动
docker compose --env-file .env.production pull
docker compose --env-file .env.production up -d

# 查看状态与日志
docker compose ps
docker compose logs -f
```

### 5. 初始化数据库

`mysql_data/` 为空时 MySQL 会首次初始化（耗时较长，等日志出现 `ready for connections`）。然后导入 SQL：

```bash
docker compose exec -T mysql mysql -uroot -p123123 starNotepad < starNotepad.sql
```

> 若修改了数据库密码，把 `123123` 替换成新密码。

### 6. 防火墙 / 安全组

建议只对公网开放：

```text
80    HTTP
443   HTTPS（配置 SSL 后）
8100  BlueMap（可选）
8899  管理后台（可选）
```

不建议对公网开放 `3306`（MySQL）和 `8888`（后端 API）。

---

## 三、更新发布

代码改动后，本地重新推送镜像，服务器拉取重建。

```bash
# 本地：构建并推送（详见镜像推送说明）
./push-images.sh latest

# 服务器：拉取并重建
cd /opt/notepad
docker compose --env-file .env.production pull
docker compose --env-file .env.production up -d --force-recreate
```

> 生产环境已启用 watchtower，默认每 5 分钟检查带 `watchtower.enable=true` 标签的容器并自动更新。

---

## 四、镜像推送（阿里云 ACR）

`push-images.sh` 会构建后端、管理后台、个人主页三个镜像，并为 BlueMap 基础镜像打标签，全部推送到同一个 ACR 仓库的不同 tag。

```bash
REGISTRY_USERNAME=你的ACR用户名 \
REGISTRY_PASSWORD=你的ACR密码 \
./push-images.sh latest

# 已登录过可跳过登录
SKIP_LOGIN=1 ./push-images.sh latest
```

仓库与 tag：

```text
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles
  ├── gva-server-latest
  ├── admin-web-latest
  ├── home-web-latest
  └── bluemap-jre-25
```

MySQL、Nginx、Watchtower 不推送，生产直接用公共镜像（`mysql:8.0.45`、`nginx:alpine`、`containrrr/watchtower`）。

---

## 五、安全建议

1. **改默认密码**：`123123` 出现在 `.env.production`、`docker-compose.yml`、`gin-vue-admin/server/config.yaml` 三处，改时必须三处同步。
2. **限制端口**：仅对外开放 80/443，其余服务走内网。
3. **启用 HTTPS**：
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```
4. **定期备份**：
   ```bash
   docker compose exec mysql mysqldump -u root -p starNotepad > backup.sql
   tar -czf uploads_backup.tar.gz uploads/
   ```

遇到部署问题，见 [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)。
