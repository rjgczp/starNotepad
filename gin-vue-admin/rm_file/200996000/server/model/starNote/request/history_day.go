
package request

import (
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
	"time"
)

type HistoryDaySearch struct{
    CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
      Month  *int `json:"month" form:"month"` 
      Day  *int `json:"day" form:"day"` 
      Year  *int `json:"year" form:"year"` 
      Title  *string `json:"title" form:"title"` 
      Content  string `json:"content" form:"content"` 
      Type  string `json:"type" form:"type"` 
    request.PageInfo
    Sort  string `json:"sort" form:"sort"`
    Order string `json:"order" form:"order"`
}
