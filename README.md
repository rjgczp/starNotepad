# 星记事 (Star Notepad)
“星记事”是一款基于 Flutter 开发的前端移动端应用，搭配 Gin-Vue-Admin (GVA) 后端框架，旨在为用户提供轻量、高效、且支持 AI 辅助的个人笔记与日记管理工具。

## 🚀 项目架构
前端 (Flutter): 跨平台移动端应用。

后端 (Go): 基于 Gin 框架的高性能 API 服务。

数据库: MySQL 8.0。

管理后台: Gin-Vue-Admin (Vue3)。

## 📦 部署方式 (Docker 快速部署)
本项目支持通过 docker-compose 一键式部署。（同时仅提供 docker-compose部署教程）

##### 第一阶段：服务器环境准备
购买与连接：购买一台 Ubuntu 22.04/24.04 服务器，通过 ssh ubuntu@IP 连接。

安装 Docker & Compose：

Bash
安装 Docker
curl -fsSL https://get.docker.com | bash
确保 Docker Compose 可用 (Ubuntu 24.04 通常自带)
docker compose version

##### 第二阶段：项目部署流程
代码克隆与同步：

Bash
mkdir -p ~/projects/notepad && cd ~/projects/notepad
git clone https://github.com/your-username/starNotepad.git

配置文件对齐（关键避坑）：

问题：config.docker.yaml 与本地 config.yaml 配置不一致导致路由 404 或初始化失败。

解决：在 docker-compose.yml 中统一映射 config.yaml，并强制后端读取它：

YAML
environment:
  - GVA_CONFIG=/app/config.yaml
volumes:
  - ./gin-vue-admin/server/config.yaml:/app/config.yaml

#### 第三阶段：数据库初始化与避坑指南
场景 1：数据库初始化报 connection refused
现象：dial tcp 127.0.0.1:3306: connect: connection refused

排查：后端容器试图连接自己而非 MySQL 容器。

解决：修改 config.yaml 中的 mysql.path 为 gva-mysql:3306（Docker 网络内使用服务名，不要用 127.0.0.1）。

场景 2：报 Access denied (root@...)
现象：数据库报错拒绝连接，即使密码看起来是对的。

核心排查点：

残留数据干扰：MySQL 数据卷中存有旧的授权信息。

执行清理：docker compose down -v 并 sudo rm -rf mysql_data/。

重新启动：MySQL 8.0 第一次初始化非常耗时，一定要等待日志显示 ready for connections，然后再去操作初始化接口。

#### 第四阶段：路由与接口 404 排查 SOP
当你遇到 POST /api/ua/login 报 404 时，按此顺序排查：

检查后端路由表：

执行 docker compose logs --tail 200 gva-server | grep "GIN-debug" | grep "POST"。

逻辑：如果列表中没有 /api/ua/login，说明后端代码没注册这个路径，或者构建的镜像还没更新。

使用 Nginx Rewrite 规则：

如果不想改后端代码，通过 nginx.conf 处理：

Nginx
location /api/ {
    rewrite ^/api/(.*)$ /$1 break;
    proxy_pass http://gva-server:8888;
}
解决办法：修改后务必运行 docker compose restart gva-web。

### 第五阶段：数据持久化同步
如果本地数据库有大量配置，直接迁移是最好的。

本地导出：mysqldump -u root -p database_name > local.sql

上传：scp -i ~/.ssh/Mac.pem local.sql ubuntu@IP:~/projects/notepad/

导入：docker exec -i gva-mysql mysql -uroot -p123123 starNotepad < local.sql

# 📝 版权声明
本项目的代码及文档遵循 **[MIT 许可证](https://opensource.org/license/MIT)**。

说明：

本项目为开源项目，旨在技术交流与个人学习。

本后台系统基于 Gin-Vue-Admin 开源框架开发，核心业务模块由本人自主研发。

开发者不承担因使用本项目而导致的任何数据丢失、服务器损坏或法律纠纷风险。

如需在商业环境中使用，请确保符合相关法律法规，并保留原作者的版权声明。

💡 关于赞赏
如果你觉得“星记事”对你有帮助，欢迎通过以下方式支持项目的发展。您的支持是我持续更新的动力！

<img width="1037" height="1037" alt="赞赏码" src="https://github.com/user-attachments/assets/b6b3784a-0fc0-4961-99bd-0893061bddff" />


🤝 反馈与交流
如果有任何 Bug 或改进建议，欢迎提交 [Issues](https://)。
