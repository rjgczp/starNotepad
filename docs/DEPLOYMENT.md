# 生产部署与公网接入

本文对应当前 `docker-compose.yml`、`nginx.conf` 和 `deploy/` 脚本。旧的 `logs/docs/` 文档已经过时，不应再作为部署依据。

## 当前生产信息

| 项目 | 当前值 |
| --- | --- |
| 公网 IP | `82.157.105.7` |
| 主域名 | `xiaoyu.ski` |
| 镜像仓库 | 阿里云 ACR，北京 |
| 容器平台 | `linux/amd64` |
| TLS 文件 | `/home/ubuntu/opt/data/ssl/xiaoyu.ski.{pem,key}` |
| 数据时区 | `Asia/Shanghai` |

浏览器入口见根 [README](../README.md#公网入口)。这些入口已于 2026-07-29 实测可访问；服务器迁移后应重新检查。

## 1. 服务器要求

- 推荐 Ubuntu 22.04/24.04 x86_64。
- 已安装 Docker Engine 与 Compose v2。
- 至少 4 GB 内存和足够存放 MySQL、上传文件、BlueMap 世界与切片的磁盘。
- 服务器安全组和系统防火墙允许所需端口。

确认环境：

```bash
docker version
docker compose version
uname -m
```

## 2. DNS

为以下主机创建指向 `82.157.105.7` 的 A 记录：

```text
xiaoyu.ski
home.xiaoyu.ski
blog.xiaoyu.ski
ai.xiaoyu.ski
ht.xiaoyu.ski
map.xiaoyu.ski
turn.xiaoyu.ski
```

迁移服务器时，先修改 DNS 和 `TURN_EXTERNAL_IP`，等待解析生效，再签发证书和开放服务。

## 3. 防火墙与安全组

公网开放：

| 协议 | 端口 | 用途 |
| --- | ---: | --- |
| TCP | 80 | HTTP 跳转和 Certbot 校验 |
| TCP | 443 | 所有 Web HTTPS 入口 |
| TCP/UDP | 3478 | STUN/TURN |
| TCP/UDP | 49152-49200 | TURN 中继端口 |

不要对公网开放 MySQL `3306`、后端 `8888`、BlueMap `8100` 或前端容器端口。它们均由 Docker 网络和 Nginx 访问。

## 4. 准备运行目录

以下以 `/opt/notepad` 为例：

```bash
sudo mkdir -p /opt/notepad
sudo chown -R "$USER":"$USER" /opt/notepad
cd /opt/notepad
```

生产虽然使用预构建镜像，仍需要以下仓库文件或等价内容：

```text
docker-compose.yml
nginx.conf
deploy/
gin-vue-admin/server/config.yaml
bluemap/cli.jar
bluemap/config/
bluemap/data/
bluemap/web/
bluemap/active-world/
uploads/
logs/
mysql_data/
```

`bluemap/active-world/`、数据库、上传文件和生成后的 BlueMap 数据不会随 Git 仓库自动获得。新服务器必须从备份恢复，或提供新的世界数据。

## 5. 准备环境变量

```bash
cp .env.example .env.production
chmod 600 .env.production
./deploy/prepare-production-env.sh
```

随后编辑 `.env.production`：

- 将 `MYSQL_ROOT_PASSWORD=change_me` 换成强密码。
- 核对所有业务镜像标签。
- 确认 `TURN_EXTERNAL_IP=82.157.105.7`。
- 微信未启用时保持 `WX_TEST_ENABLED=false`。
- 微信启用时填写 AppID、AppSecret、模板 ID，并设置 `DUO_PUBLIC_BASE_URL=https://ai.xiaoyu.ski`。

校验时不会打印密钥：

```bash
docker compose --env-file .env.production -f docker-compose.yml config --quiet
```

不要把无 `--quiet` 的完整 Compose 渲染结果粘贴到公开位置，因为其中会包含展开后的秘密。

## 6. 准备持久化数据

至少创建目录：

```bash
mkdir -p mysql_data uploads logs
mkdir -p bluemap/config bluemap/data bluemap/web bluemap/active-world
```

已有生产环境应从备份恢复 `mysql_data/`、`uploads/` 和 BlueMap 数据。全新环境可以让 MySQL 创建空数据目录，再按管理后台初始化流程创建首个管理员；后端会执行当前启用的自动迁移。不要使用仓库根部的 `dump.rdb` 初始化 MySQL，它是旧 Redis 文件。

## 7. 准备 TLS 证书

Compose 将宿主机证书固定挂载为：

```text
/home/ubuntu/opt/data/ssl/xiaoyu.ski.pem
/home/ubuntu/opt/data/ssl/xiaoyu.ski.key
```

确保证书目录存在：

```bash
sudo mkdir -p /home/ubuntu/opt/data/ssl
sudo mkdir -p /home/ubuntu/opt/data/letsencrypt
```

`deploy/renew-production-cert.sh` 会临时停止 Nginx、使用 Certbot standalone 监听 80，并为六个 Web 域名签发/扩展证书。它不会给 `turn.xiaoyu.ski` 签发证书，因为当前 TURN 配置未启用 TLS 监听。

```bash
./deploy/renew-production-cert.sh
```

证书脚本包含 `/home/ubuntu` 固定路径；换用户或目录前应先修改脚本、Compose 与 Nginx 三处。

## 8. 登录镜像仓库并启动

```bash
docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
./deploy-production.sh
```

部署脚本依次执行配置校验、拉取镜像、`up -d --remove-orphans` 和状态查看。

检查：

```bash
docker compose --env-file .env.production ps
docker compose --env-file .env.production logs --tail 100 gva-server
docker compose --env-file .env.production logs --tail 100 gva-web
```

## 9. 发布新镜像

在具备 Go、Docker buildx 和 ACR 权限的构建机执行：

```bash
cp gin-vue-admin/web/.env.production.example gin-vue-admin/web/.env.production
./push-images.sh 20260729
```

当前脚本会一次构建并推送五个业务镜像：

```text
gva-server-20260729
admin-web-20260729
home-web-20260729
blog-frontend-20260729
duo-call-web-20260729
```

脚本没有旧文档所描述的“选择单个目标”“只构建”“预览”等参数。发布固定版本后，更新服务器 `.env.production` 中的五个镜像值，再运行：

```bash
./deploy-production.sh
```

若继续使用 `latest`，Watchtower 每 300 秒检查带标签的业务容器并更新；数据库、Nginx、Coturn 和 Watchtower 本身不会被这套标签自动更新。

## 10. 上线验收

```bash
for url in \
  https://xiaoyu.ski \
  https://home.xiaoyu.ski \
  https://blog.xiaoyu.ski \
  https://ai.xiaoyu.ski \
  https://ht.xiaoyu.ski \
  https://map.xiaoyu.ski
do
  curl -L -sS -o /dev/null -w '%{http_code} %{url_effective}\n' "$url"
done
```

还应人工验证：

- 管理后台登录、上传文件和 API 请求。
- 博客数据是否能从后端加载。
- 情侣空间双身份登录、WebSocket、图片、每日回信。
- 两个不同网络下的 WebRTC 通话，以确认 TURN 和中继端口。
- BlueMap 地图切片和世界是否正确。
- Flutter 真机使用 `BASE_URL=https://xiaoyu.ski` 后可以登录与同步。
