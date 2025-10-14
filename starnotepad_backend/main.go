package main

import (
	"log"

	"starnotepad-backend/database"
	"starnotepad-backend/routes"

	"github.com/gin-gonic/gin"
)

func main() {
	// 初始化数据库
	database.InitDB()
	// 创建Gin路由
	r := gin.Default()

	// 设置路由
	routes.SetupRoutes(r)

	// 启动服务器
	log.Println("服务器启动在 :8080")
	r.Run(":8080")
}
