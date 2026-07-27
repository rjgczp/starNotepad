package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
)

type ProviderSearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	request.PageInfo
}

type ProviderInvokeReq struct {
	Path    string            `json:"path" form:"path" binding:"required"`
	Method  string            `json:"method" form:"method"`
	Headers map[string]string `json:"headers" form:"headers"`
	Params  map[string]string `json:"params" form:"params"`
	Body    any               `json:"body" form:"body"`
}
