星记事 (Star Notepad)
“星记事”是一款基于 Flutter 开发的前端移动端应用，搭配 Gin-Vue-Admin (GVA) 后端框架，旨在为用户提供轻量、高效、且支持 AI 辅助的个人笔记与日记管理工具。

🚀 项目架构
前端 (Flutter): 跨平台移动端应用。

后端 (Go): 基于 Gin 框架的高性能 API 服务。

数据库: MySQL 8.0。

管理后台: Gin-Vue-Admin (Vue3)。

📦 部署方式 (Docker 快速部署)
本项目支持通过 docker-compose 一键式部署。

1. 前置条件
安装 Docker 和 Docker Compose。

在服务器上克隆本项目。

2. 环境配置
在项目根目录下创建一个 .env 文件，配置数据库密码：

Plaintext
DB_PASSWORD=你的数据库密码
3. 启动项目
确保你在项目根目录下，执行以下命令：

Bash
# 启动所有服务（后端、数据库、前端代理）
docker compose up -d
4. 访问服务
API 服务: http://你的服务器IP:8888

后台管理/前端入口: http://你的服务器IP:80

🛠 开发指南
本地调试
后端: 进入 server 目录，修改 config.yaml，运行 go run main.go。

前端: 进入 flutter_app 目录，运行 flutter run。

📝 版权声明
本项目的代码及文档遵循 MIT 许可证。

说明：

本项目为开源项目，旨在技术交流与个人学习。

开发者不承担因使用本项目而导致的任何数据丢失、服务器损坏或法律纠纷风险。

如需在商业环境中使用，请确保符合相关法律法规，并保留原作者的版权声明。

💡 关于赞赏
如果你觉得“星记事”对你有帮助，欢迎通过以下方式支持项目的发展。您的支持是我持续更新的动力！

<img width="1037" height="1037" alt="赞赏码" src="https://github.com/user-attachments/assets/b6b3784a-0fc0-4961-99bd-0893061bddff" />


🤝 反馈与交流
如果有任何 Bug 或改进建议，欢迎提交 Issues。
