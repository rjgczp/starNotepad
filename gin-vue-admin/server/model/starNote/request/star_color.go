package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
)

type StarColorSearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	request.PageInfo
}

// UserStarColorCreateReq 用户端创建颜色
type UserStarColorCreateReq struct {
	Color string `json:"color" binding:"required"` // 颜色值，例如 #ffffff
	Name  string `json:"name" binding:"required"`  // 颜色名字
}

// UserStarColorUpdateReq 用户端更新颜色
type UserStarColorUpdateReq struct {
	ID    uint   `json:"id" binding:"required"`
	Color string `json:"color" binding:"required"`
	Name  string `json:"name" binding:"required"`
}

// UserStarColorDeleteReq 用户端删除颜色
type UserStarColorDeleteReq struct {
	ID uint `json:"id" binding:"required"`
}
