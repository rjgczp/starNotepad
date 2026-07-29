# 仓库冗余与安全检查

检查日期：2026-07-29。

## 已整理

- 根 README 已按当前七个业务/基础组件重写。
- 新建统一 `docs/` 索引，并补齐架构、开发、配置、部署、运维文档。
- 公网六个 HTTPS 入口已实际检测，均返回 200，解析到 `82.157.105.7`。
- `.env.example` 已补充实际使用但原先缺失的 `WX_TEST_ENABLED`、HTTPS 和开发端口说明。
- Duo 的 ICE 示例域名已从旧的 `call.xiaoyu.ski` 改为当前 `turn.xiaoyu.ski`。
- 旧部署文档中不存在的 `starNotepad.sql`、已经失效的默认密码示例、错误端口和旧版镜像脚本参数未再沿用。

## 明确可忽略的本地产物

以下内容已由 `.gitignore` 覆盖，不属于源码：

```text
.DS_Store
node_modules/
.next/
dist/
mysql_data/
uploads/
logs/
bluemap/web/
bluemap/active-world/
```

它们可以在本机占用较大空间，但 `mysql_data/`、`uploads/`、BlueMap 世界和生成数据属于生产持久化内容，不能按普通构建缓存删除。

## 候选冗余

### `logs/docs/`

该目录位于被忽略的运行日志目录内，包含旧版 `DEPLOYMENT.md`、`PUSH_IMAGES_GUIDE.md`、`TROUBLESHOOTING.md`。内容与当前 Compose/脚本明显不一致：

- 漏掉博客、情侣空间和 Coturn。
- 引用不存在的 `starNotepad.sql`。
- 描述了当前 `push-images.sh` 不支持的参数。
- 建议用删除数据库目录处理鉴权错误，存在数据丢失风险。

现在的权威文档已迁移到根 `docs/`。旧文件未自动删除，以免误删本地历史资料；确认不再需要后可手工移出或删除。

### `dump.rdb`

根目录 `dump.rdb` 是已被 Git 跟踪的约 1.4 KB Redis 快照。内容可识别为旧的用户角色、菜单、按钮和 API 权限缓存；当前后端配置 `use-redis: false`，Compose 也没有 Redis 服务，因此它不参与当前部署。

建议在确认没有恢复价值后，从 Git 删除并在 `.gitignore` 增加 `dump.rdb`，以免继续分发历史权限数据。本次未删除，因为它是已跟踪的数据快照，无法代替项目所有者决定其历史恢复价值。

### 重复的后端 YAML

`config.yaml` 与 `config.docker.yaml` 大量重复，分别服务生产与本地容器。它们不是立即可删的重复文件，但存在配置漂移风险。当前 Duo 定时任务等新增段落需要在两份文件中同步。

长期建议保留一个基础配置，并仅通过环境变量覆盖数据库主机、密钥和环境差异；实施前需先补齐配置加载测试。

### 未使用的 Compose 命名卷

`docker-compose.dev.yml` 声明了：

```text
gva-go-mod-cache
gva-go-build-cache
```

但后端实际挂载的是当前电脑专属绝对路径 `/Users/sansea/...`。两个命名卷目前未使用，且绝对路径妨碍其他开发者直接启动。

建议后续把两个绝对路径挂载替换为这两个命名卷，再删除机器专属路径。该调整会改变构建缓存行为，未在纯文档整理中修改。

### Gin-Vue-Admin 上游示例配置

后端 YAML 保留了 OSS、Redis、Mongo 和多种数据库的大量占位配置。当前运行不会使用它们，但 Gin-Vue-Admin 的配置结构和系统配置页面可能仍引用这些字段，不建议只为缩短文件直接删除。

## 需要注意但不属于冗余

- `blog-frontend/` 是嵌套 Git 仓库/父仓库 gitlink，不是普通目录；提交文档或代码时需要分别处理其提交。
- `openspec/changes/` 是功能设计和任务记录。已完成变更应走 OpenSpec 归档流程，不要把整个目录当缓存清理。
- `Dockerfile.release` 是基于已有镜像覆盖产物的快速发布路径，与完整构建 Dockerfile 用途不同。
- `.env.production`、证书、数据库目录虽不进 Git，却是生产恢复所需材料，必须安全备份。
