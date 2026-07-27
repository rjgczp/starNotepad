
// 自动生成模板McWorld
package mc
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"time"
)

// MC世界 结构体  McWorld
type McWorld struct {
    global.GVA_MODEL
  Name  *string `json:"name" form:"name" gorm:"column:name;" binding:"required"`  //世界名称
  Slug  *string `json:"slug" form:"slug" gorm:"comment:唯一索引;column:slug;" binding:"required"`  //唯一标识
  Description  *string `json:"description" form:"description" gorm:"column:description;type:text;"`  //描述
  McVersion  *string `json:"mcVersion" form:"mcVersion" gorm:"column:mc_version;"`  //MC版本
  Platform  *string `json:"platform" form:"platform" gorm:"default:java;column:platform;"`  //平台
  WorldPath  *string `json:"worldPath" form:"worldPath" gorm:"column:world_path;" binding:"required"`  //路径
  MapUrl  *string `json:"mapUrl" form:"mapUrl" gorm:"column:map_url;type:text;"`  //地图链接
  RenderStatus  *int64 `json:"renderStatus" form:"renderStatus" gorm:"comment:默认0;column:render_status;"`  //渲染状态
  RenderError  *string `json:"renderError" form:"renderError" gorm:"column:render_error;type:text;"`  //错误信息
  LastRenderAt  *time.Time `json:"lastRenderAt" form:"lastRenderAt" gorm:"column:last_render_at;"`  //最后渲染时间
  IsPublic  *bool `json:"isPublic" form:"isPublic" gorm:"comment:默认1;column:is_public;"`  //是否公开
  Sort  *int64 `json:"sort" form:"sort" gorm:"column:sort;"`  //排序
}


// TableName MC世界 McWorld自定义表名 mc_world
func (McWorld) TableName() string {
    return "mc_world"
}





