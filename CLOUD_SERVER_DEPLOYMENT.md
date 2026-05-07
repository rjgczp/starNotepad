# 云服务器部署与镜像推送说明

本文档说明如何把当前项目镜像推送到阿里云容器镜像服务 ACR，并在云服务器上拉取镜像运行。

## 1. 本地推送镜像会发生什么

在项目根目录执行：

```bash
REGISTRY_USERNAME=你的阿里云ACR用户名 \
REGISTRY_PASSWORD=你的阿里云ACR密码 \
./push-images.sh latest
```

脚本会执行以下操作：

1. 登录阿里云 ACR。
2. 构建后端服务镜像 `gva-server-latest`。
3. 构建后台管理前端镜像 `admin-web-latest`。
4. 构建个人主页镜像 `home-web-latest`。
5. 拉取 BlueMap 运行环境镜像 `eclipse-temurin:25-jre`。
6. 给 BlueMap 运行环境镜像打阿里云 ACR 标签 `bluemap-jre-25`。
7. 推送 4 个镜像到阿里云 ACR。

如果你已经在本机登录过阿里云 ACR，也可以执行：

```bash
SKIP_LOGIN=1 ./push-images.sh latest
```

## 2. 阿里云 ACR 中会看到什么

当前使用的是同一个镜像仓库、多个 tag 的方式。

仓库地址：

```text
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles
```

推送完成后，ACR 中应该看到 1 个仓库：

```text
charles1337 / charles
```

这个仓库下面有 4 个 tag：

```text
gva-server-latest
admin-web-latest
home-web-latest
bluemap-jre-25
```

MySQL 不推送到阿里云 ACR，生产环境仍使用官方镜像：

```text
mysql:8.0.45
```

## 3. 云服务器目录结构

推荐把项目运行文件放到：

```text
/opt/notepad
```

推荐目录结构：

```text
/opt/notepad/
├── docker-compose.yml
├── .env.production
├── nginx.conf
├── starNotepad.sql
├── gin-vue-admin/
│   └── server/
│       └── config.yaml
├── bluemap/
│   ├── cli.jar
│   ├── config/
│   ├── data/
│   ├── web/
│   └── active-world/
├── uploads/
├── logs/
└── mysql_data/
```

## 4. 必须上传到云服务器的文件

### 4.1 核心部署文件

```text
docker-compose.yml
.env.production
nginx.conf
```

用途：

- `docker-compose.yml`：生产服务编排文件。
- `.env.production`：生产环境变量和阿里云 ACR 镜像地址。
- `nginx.conf`：容器内 Nginx 反向代理配置。

### 4.2 后端配置文件

```text
gin-vue-admin/server/config.yaml
```

注意：

`.env.production` 中的：

```env
MYSQL_ROOT_PASSWORD=123123
```

必须和 `gin-vue-admin/server/config.yaml` 中的：

```yaml
mysql:
  password: "123123"
```

保持一致。

如果上云后要改成强密码，两个地方必须一起改。

### 4.3 BlueMap 文件

```text
bluemap/cli.jar
bluemap/config/
bluemap/data/
bluemap/web/
bluemap/active-world/
```

注意：

BlueMap 镜像只是 Java 运行环境，真正的 BlueMap 程序、配置、webroot 和世界目录仍然来自服务器本地挂载目录。

### 4.4 运行目录

这些目录需要存在，可以为空：

```text
uploads/
logs/
mysql_data/
```

用途：

- `uploads/`：后端上传文件目录。
- `logs/`：后端日志目录。
- `mysql_data/`：MySQL 数据目录。

如果你想让云服务器重新初始化数据库，`mysql_data/` 可以为空，然后导入 `starNotepad.sql`。

如果你想迁移本地数据库，可以迁移本地 `mysql_data/`，但要注意 MySQL 版本和文件权限。

## 5. 不需要上传的内容

如果云服务器只负责运行容器，这些源码和构建产物不需要上传：

```text
personal-home-next/
gin-vue-admin/web/
node_modules/
.next/
dist/
build/
personal-home-next.zip
.env.local
docker-compose.dev.yml
docker-compose.override.yml
```

说明：

- `personal-home-next/` 已经打进 `home-web-latest` 镜像。
- `gin-vue-admin/web/` 已经打进 `admin-web-latest` 镜像。
- 后端源码已打进 `gva-server-latest` 镜像，但 `config.yaml` 仍需要挂载。

## 6. 云服务器初始化步骤

### 6.1 创建目录

```bash
sudo mkdir -p /opt/notepad
sudo chown -R $USER:$USER /opt/notepad
cd /opt/notepad
```

### 6.2 创建运行目录

```bash
mkdir -p uploads logs mysql_data gin-vue-admin/server
mkdir -p bluemap/config bluemap/data bluemap/web bluemap/active-world
```

### 6.3 上传文件

可以用 `scp` 上传：

```bash
scp docker-compose.yml .env.production nginx.conf user@服务器IP:/opt/notepad/
scp starNotepad.sql user@服务器IP:/opt/notepad/
scp gin-vue-admin/server/config.yaml user@服务器IP:/opt/notepad/gin-vue-admin/server/config.yaml
scp -r bluemap/cli.jar bluemap/config bluemap/data bluemap/web bluemap/active-world user@服务器IP:/opt/notepad/bluemap/
```

也可以先上传整个项目，再按需删除源码和本地开发文件。

## 7. 云服务器启动服务

### 7.1 登录阿里云 ACR

```bash
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
```

### 7.2 拉取镜像

```bash
cd /opt/notepad
docker compose --env-file .env.production pull
```

会拉取：

```text
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:gva-server-latest
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:admin-web-latest
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:home-web-latest
crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:bluemap-jre-25
mysql:8.0.45
nginx:alpine
containrrr/watchtower:latest
```

其中前 4 个来自阿里云 ACR，MySQL、Nginx 和 Watchtower 仍来自公共镜像源。

### 7.3 启动服务

```bash
docker compose --env-file .env.production up -d
```

### 7.4 查看状态

```bash
docker compose ps
```

### 7.5 查看日志

```bash
docker compose logs -f
```

查看单个服务日志：

```bash
docker compose logs -f gva-server
docker compose logs -f home-web
docker compose logs -f admin-web
docker compose logs -f bluemap
```

## 8. 数据库初始化

如果 `mysql_data/` 是空目录，MySQL 会首次初始化数据库。

确认 MySQL 启动后，可以导入 SQL：

```bash
docker compose exec -T mysql mysql -uroot -p123123 starNotepad < starNotepad.sql
```

如果你修改了数据库密码，把命令中的 `123123` 替换成新密码。

## 9. 访问地址

默认端口：

```text
个人主页：http://服务器IP/
管理后台：http://服务器IP:8899/
后端 API：http://服务器IP:8888/
BlueMap：http://服务器IP:8100/
```

建议云服务器安全组或防火墙只对外开放：

```text
80
443
8100 可选
8899 可选
```

不建议对公网开放：

```text
3306
8888
```

## 10. 常见问题

### 10.1 后端连接 MySQL 失败

检查两个地方是否一致：

```env
MYSQL_ROOT_PASSWORD=123123
```

```yaml
mysql:
  password: "123123"
```

还要确认 `config.yaml` 中 MySQL 地址是 Docker 服务名：

```yaml
mysql:
  path: ${DB_PATH:-127.0.0.1}
```

生产 compose 会设置：

```yaml
DB_PATH: mysql
```

### 10.2 BlueMap 容器启动但没有地图

检查：

```text
bluemap/active-world/
bluemap/config/
bluemap/web/
```

BlueMap 需要世界目录和配置文件，镜像本身不包含地图数据。

### 10.3 云服务器拉镜像失败

先确认已登录 ACR：

```bash
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
```

再单独拉一个镜像测试：

```bash
docker pull crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:home-web-latest
```

### 10.4 修改前端或后端代码后如何更新

本地重新推送镜像：

```bash
./push-images.sh latest
```

服务器拉取并重建容器：

```bash
cd /opt/notepad
docker compose --env-file .env.production pull
docker compose --env-file .env.production up -d --force-recreate
```

## 11. 最简命令汇总

本地推送：

```bash
REGISTRY_USERNAME=你的阿里云ACR用户名 \
REGISTRY_PASSWORD=你的阿里云ACR密码 \
./push-images.sh latest
```

服务器启动：

```bash
cd /opt/notepad
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
docker compose --env-file .env.production pull
docker compose --env-file .env.production up -d
docker compose ps
```
