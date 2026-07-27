package system

import "github.com/flipped-aurora/gin-vue-admin/server/global"

// MainImage is an image shown by the personal-home easter egg.
type MainImage struct {
	global.GVA_MODEL
	Name    string `json:"name" gorm:"size:128;comment:display name"`
	URL     string `json:"url" binding:"required" gorm:"size:1024;not null;comment:image url"`
	Sort    int    `json:"sort" gorm:"default:0;index;comment:display order"`
	Enabled bool   `json:"enabled" gorm:"default:true;index;comment:visible on homepage"`
}

func (MainImage) TableName() string { return "main_images" }
