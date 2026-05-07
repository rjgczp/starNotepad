# 部署指南

## 概述

本项目使用统一的 Docker 配置，支持本地开发和云服务器部署。

## 配置文件说明

- `docker-compose.yml` - 主要配置文件（生产就绪）
- `docker-compose.dev.yml` - 本地 Docker 开发配置
- `.env.local` - 本地开发环境变量
- `.env.production` - 生产环境环境变量  
- `docker-compose-bluemap-only.yml` - 仅启动 BlueMap 的按需配置

## 本地开发部署

### 方式 1：使用本地 Docker 开发配置（推荐）

```bash
# 启动本地开发环境
docker-compose -f docker-compose.dev.yml --env-file .env.local up -d

# 查看服务状态
docker-compose -f docker-compose.dev.yml ps

# 查看日志
docker-compose -f docker-compose.dev.yml logs -f

# 重新运行
docker-compose -f docker-compose.dev.yml up -d --build
```

### 方式 2：停止本地开发环境

```bash
docker-compose -f docker-compose.dev.yml down
```

### 本地开发访问地址

- **后端管理**: http://localhost:8888
- **Next.js 主页**: http://localhost:3000
- **BlueMap 地图**: http://localhost:8100
- **管理后台开发页**: http://localhost:5173

> 当前本地开发环境使用 `docker-compose.dev.yml` 中的本地 MySQL 服务，默认宿主机端口由 `.env.local` 的 `MYSQL_PORT` 控制。

## 云服务器部署

### 1. 准备服务器环境

```bash
# 安装 Docker 和 Docker Compose
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

### 2. 上传项目文件

```bash
# 上传整个项目到服务器
scp -r /Users/charles/Documents/notepad user@your-server:/opt/

# 登录服务器
ssh user@your-server
cd /opt/notepad
```

### 3. 配置生产环境

```bash
# 复制并修改生产环境配置
cp .env.production .env

# 编辑配置文件
nano .env
```

**重要配置项：**
```env
MYSQL_ROOT_PASSWORD=your_secure_password_here  # 修改为安全密码
BLUEMAP_PORT=8100
```

> 注意：当前后端容器挂载 `gin-vue-admin/server/config.yaml`，其中 `mysql.password` 需要和 `MYSQL_ROOT_PASSWORD` 保持一致。修改数据库密码时必须同步修改这两个位置，否则后端会连接数据库失败。

### 4. 启动生产服务

```bash
# 启动所有服务
docker compose --env-file .env.production up -d

# 查看服务状态
docker compose ps

# 查看日志
docker compose logs -f
```

### 5. 配置防火墙

```bash
# 开放必要端口
sudo ufw allow 80      # HTTP
sudo ufw allow 443     # HTTPS (如果配置了 SSL)
sudo ufw allow 8888    # 后端管理 (可选，仅内网访问)
sudo ufw allow 8100    # BlueMap (可选，仅内网访问)
```

## 🔧 服务管理

### 常用命令

```bash
# 启动所有服务
docker-compose up -d

# 停止所有服务
docker-compose down

# 重启特定服务
docker-compose restart gva-server

# 查看服务状态
docker-compose ps

# 查看日志
docker-compose logs -f [service-name]

# 进入容器调试
docker-compose exec gva-server sh
```

### 更新服务

```bash
# 拉取最新镜像
docker-compose pull

# 重新创建服务
docker-compose up -d --force-recreate
```

## 🌐 网络配置

### 生产环境建议架构

```
Internet
    ↓
[Nginx/反向代理:80,443]
    ↓
[Next.js:3000] [BlueMap:8100] [管理后台:8899]
    ↓
[后端API:8888]
    ↓
[MySQL:3306] [BlueMap:8100]
```

### 反向代理配置示例

```nginx
# /etc/nginx/sites-available/notepad
server {
    listen 80;
    server_name your-domain.com;

    # Next.js 主页
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # BlueMap
    location /minecraft {
        proxy_pass http://localhost:8100;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 后端 API
    location /api {
        proxy_pass http://localhost:8888;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

## 🔒 安全配置

### 生产环境安全建议

1. **修改默认密码**
   ```env
   MYSQL_ROOT_PASSWORD=your_secure_password_here
   ```
   同时修改 `gin-vue-admin/server/config.yaml` 中的 `mysql.password`。

2. **限制端口访问**
   - 仅开放 80 和 443 端口到外网
   - 其他服务仅内网访问

3. **启用 HTTPS**
   ```bash
   # 使用 Let's Encrypt
   sudo apt install certbot python3-certbot-nginx
   sudo certbot --nginx -d your-domain.com
   ```

4. **定期备份**
   ```bash
   # 备份数据库
   docker-compose exec mysql mysqldump -u root -p starNotepad > backup.sql
   
   # 备份上传文件
   tar -czf uploads_backup.tar.gz uploads/
   ```

## 🐛 故障排除

### 常见问题

1. **端口冲突**
   ```bash
   # 检查端口占用
   sudo netstat -tlnp | grep :8888
   
   # 修改端口配置
   nano .env
   ```

2. **数据库连接失败**
   ```bash
   # 检查 MySQL 状态
   docker-compose logs mysql
   
   # 重启数据库
   docker-compose restart mysql
   ```

3. **BlueMap 无法访问**
   ```bash
   # 检查世界目录挂载
   docker-compose exec bluemap ls -la /app/world
   
   # 重新创建活跃世界链接
   cd /opt/notepad
   ln -sf /path/to/your/world ./bluemap/active-world
   ```

## 📞 技术支持

如遇问题，请检查：
1. Docker 和 Docker Compose 版本
2. 端口是否被占用
3. 防火墙配置
4. 环境变量配置
5. 服务日志输出
