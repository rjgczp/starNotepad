package database

import (
	"log"
	"starnotepad-backend/models"

	"gorm.io/driver/mysql"
	"gorm.io/gorm"
)

var DB *gorm.DB

func InitDB() {
	dsn := "root:123123@tcp(127.0.0.1:3306)/notepad?charset=utf8mb4&parseTime=True&loc=Local"
	db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatal("无法连接到数据库:", err)
	}

	// 自动迁移数据库表结构
	err = db.AutoMigrate(&models.User{}, &models.VerificationCode{}, &models.Notepad{})
	if err != nil {
		log.Fatal("数据库迁移失败:", err)
	}
	DB = db
	log.Println("数据库连接成功")
}
