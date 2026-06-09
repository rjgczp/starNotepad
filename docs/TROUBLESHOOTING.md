# 故障排查

部署和调试中遇到的高频问题与解决方案，按场景归档。

## 数据库

### 后端报 `connection refused`

现象：`dial tcp 127.0.0.1:3306: connect: connection refused`

原因：后端容器试图连接自己（127.0.0.1）而不是 MySQL 容器。

解决：容器内必须用 Docker 服务名连接数据库。
- 生产 `docker-compose.yml` 已设置 `DB_PATH: mysql`，`config.yaml` 中 `mysql.path` 走 `${DB_PATH:-127.0.0.1}`。
- 确认 `mysql.path` 指向服务名（`mysql` 或 `gva-mysql`），不要写 `127.0.0.1`。

### 报 `Access denied (root@...)`

现象：密码看起来没错，数据库却拒绝连接。

原因：MySQL 数据卷里残留了旧的授权信息。

解决：
```bash
docker compose down -v
sudo rm -rf mysql_data/
docker compose up -d
```
> MySQL 8.0 首次初始化很慢，务必等日志出现 `ready for connections` 再操作初始化接口。

### 密码不一致导致连不上

`123123` 出现在三处，必须保持一致：
- `.env.production` → `MYSQL_ROOT_PASSWORD`
- `docker-compose.yml` → mysql 服务环境变量
- `gin-vue-admin/server/config.yaml` → `mysql.password`

改强密码时三处一起改。

## 路由与接口 404

遇到 `POST /api/ua/login` 返回 404 时，按顺序排查：

1. **检查后端路由是否注册**
   ```bash
   docker compose logs --tail 200 gva-server | grep "GIN-debug" | grep "POST"
   ```
   如果列表里没有该路径，说明后端没注册，或镜像还没更新到最新代码。

2. **检查 Nginx 转发规则**
   如果不想改后端代码，可在 `nginx.conf` 用 rewrite 去掉 `/api` 前缀：
   ```nginx
   location /api/ {
       rewrite ^/api/(.*)$ /$1 break;
       proxy_pass http://gva-server:8888;
   }
   ```
   改完重启代理：`docker compose restart gva-web`。

## BlueMap

### 容器启动但没有地图

检查这几个挂载目录是否就位：
```text
bluemap/active-world/   # 世界数据
bluemap/config/         # 配置
bluemap/web/            # webroot
```
BlueMap 镜像只是 Java 运行环境，地图数据和配置都来自挂载目录，镜像本身不含。

## 镜像与发布

### 云服务器拉镜像失败

1. 确认已登录 ACR：
   ```bash
   docker login crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com
   ```
2. 单独拉一个镜像测试：
   ```bash
   docker pull crpi-nxt6ib76b78qk7wc.cn-beijing.personal.cr.aliyuncs.com/charles1337/charles:home-web-latest
   ```

### 改了代码但服务器没更新

本地重新推送，服务器拉取重建：
```bash
./push-images.sh latest
# 服务器
docker compose --env-file .env.production pull
docker compose --env-file .env.production up -d --force-recreate
```

## 通用

### 端口冲突
```bash
sudo netstat -tlnp | grep :8888   # 查占用
# 修改 .env 中对应端口变量
```

### 排查思路清单
1. Docker 与 Compose 版本是否正常
2. 端口是否被占用
3. 防火墙 / 安全组配置
4. 环境变量是否正确
5. 看服务日志：`docker compose logs -f <service>`

## 数据迁移

本地数据库迁移到服务器：
```bash
# 本地导出
mysqldump -u root -p starNotepad > local.sql
# 上传
scp local.sql user@服务器IP:/opt/notepad/
# 服务器导入
docker compose exec -T mysql mysql -uroot -p123123 starNotepad < local.sql
```
