# Swagger 文档分组导出指南

## 功能说明

本系统支持将 Swagger API 文档按**用户端**和**管理端**分别生成和导出，方便前端开发者按需查看和使用。

## 使用方法

### 1. 生成并拆分 Swagger 文档

在 `server` 目录下执行：

```bash
# 方式一：一键生成并拆分（推荐）
make swagger-all

# 方式二：分步执行
make swagger        # 先生成完整文档
make swagger-split  # 再拆分文档
```

执行后会生成三份文档：
- `docs/swagger.json` - 完整文档（所有接口）
- `docs/swagger-user.json` - 用户端文档（只包含 User 开头的 Tag）
- `docs/swagger-admin.json` - 管理端文档（不包含 User 开头的 Tag）

### 2. 访问在线文档

启动服务后，访问以下地址：

**自定义文档页面（推荐）**：`http://127.0.0.1:8888/api/docs`

页面功能：
- **全部接口** - 显示所有 API
- **用户端** - 只显示用户端接口（UserFile、UserNote 等）
- **管理端** - 只显示管理端接口（NoteModel、NoteCategory 等）
- **导出当前JSON** - 一键下载当前显示的 JSON 文档

**原始 Swagger UI**：`http://127.0.0.1:8888/swagger/index.html`

### 3. 直接下载 JSON 文件

- 完整文档：`http://127.0.0.1:8888/api/swagger/doc.json`
- 用户端文档：`http://127.0.0.1:8888/api/swagger/swagger-user.json`
- 管理端文档：`http://127.0.0.1:8888/api/swagger/swagger-admin.json`

## 分组规则

### 用户端接口
所有 `@Tags` 以 `User` 开头的接口，例如：
- `@Tags UserFile` - 用户端文件上传下载
- `@Tags UserNote` - 用户端记事本管理
- `@Tags UserAccount` - 用户端账号管理

### 管理端接口
所有其他接口，例如：
- `@Tags NoteModel` - 管理端记事本管理
- `@Tags NoteCategory` - 管理端分类管理
- `@Tags HistoryDay` - 历史记录管理

## 开发流程

1. **添加新接口时**，在 Swagger 注解中使用正确的 Tag：
   ```go
   // 用户端接口
   // @Tags UserXxx
   
   // 管理端接口
   // @Tags Xxx
   ```

2. **修改接口后**，重新生成文档：
   ```bash
   make swagger-all
   ```

3. **重启服务**，新文档即可生效

## 文件说明

- `scripts/split-swagger.js` - 文档拆分脚本
- `static/swagger-custom.html` - 自定义 Swagger UI 页面
- `Makefile` - 文档生成命令
- `docs/swagger*.json` - 生成的文档文件

## 注意事项

1. 每次修改接口后都需要重新执行 `make swagger-all`
2. 拆分脚本依赖 Node.js，确保已安装
3. 用户端接口的 Tag 必须以 `User` 开头
4. 文档文件会自动覆盖，无需手动删除旧文件
