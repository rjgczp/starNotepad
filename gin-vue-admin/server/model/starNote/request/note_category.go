package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
)

type NoteCategorySearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	UserID         *int        `json:"userID" form:"userID"`
	request.PageInfo
}

// UserNoteCategoryCreateReq 用户端创建分类
type UserNoteCategoryCreateReq struct {
	Name  string `json:"name" binding:"required"`
	Color string `json:"color" binding:"required"`
	Icon  string `json:"icon" binding:"required"`
}

// UserNoteCategoryUpdateReq 用户端更新分类
type UserNoteCategoryUpdateReq struct {
	ID    uint   `json:"id" binding:"required"`
	Name  string `json:"name" binding:"required"`
	Color string `json:"color" binding:"required"`
	Icon  string `json:"icon" binding:"required"`
}

// UserNoteCategoryDeleteReq 用户端删除分类
type UserNoteCategoryDeleteReq struct {
	ID uint `json:"id" binding:"required"`
}
