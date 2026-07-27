.PHONY: swagger swagger-split swagger-all

# 生成完整 Swagger 文档
swagger:
	@echo "正在生成 Swagger 文档..."
	swag init -g main.go -o ./docs
	@echo "✅ Swagger 文档生成完成"

# 拆分 Swagger 文档为用户端和管理端
swagger-split:
	@echo "正在拆分 Swagger 文档..."
	node scripts/split-swagger.js
	@echo "✅ Swagger 文档拆分完成"

# 生成并拆分 Swagger 文档（一键完成）
swagger-all: swagger swagger-split
	@echo "✅ 所有 Swagger 文档已生成并拆分完成"
	@echo "   - 完整文档: docs/swagger.json"
	@echo "   - 用户端文档: docs/swagger-user.json"
	@echo "   - 管理端文档: docs/swagger-admin.json"
