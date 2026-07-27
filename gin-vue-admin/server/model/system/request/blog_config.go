package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
)

type UserBlog_configSearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	request.PageInfo
}

type PublicChatMessage struct {
	Role    string `json:"role"    binding:"required"`
	Content string `json:"content" binding:"required"`
}

type PublicChatReq struct {
	Messages []PublicChatMessage `json:"messages" binding:"required,min=1"`
}
