package system

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"gorm.io/datatypes"
)

type BlogPost struct {
	global.GVA_MODEL
	Slug        string         `json:"slug" gorm:"size:180;uniqueIndex;not null"`
	TitleZh     string         `json:"titleZh" gorm:"size:255;not null"`
	TitleEn     string         `json:"titleEn" gorm:"size:255"`
	ExcerptZh   string         `json:"excerptZh" gorm:"type:text"`
	ExcerptEn   string         `json:"excerptEn" gorm:"type:text"`
	ContentZh   string         `json:"contentZh" gorm:"type:longtext"`
	ContentEn   string         `json:"contentEn" gorm:"type:longtext"`
	Tags        datatypes.JSON `json:"tags" gorm:"type:json"`
	Published   bool           `json:"published" gorm:"default:false;index"`
	PublishedAt *time.Time     `json:"publishedAt"`
	Sort        int            `json:"sort" gorm:"default:0;index"`
}

func (BlogPost) TableName() string { return "blog_posts" }

type BlogSkill struct {
	global.GVA_MODEL
	Name          string `json:"name" gorm:"size:128;not null"`
	DescriptionZh string `json:"descriptionZh" gorm:"type:text"`
	DescriptionEn string `json:"descriptionEn" gorm:"type:text"`
	Level         int    `json:"level" gorm:"default:0"`
	Enabled       bool   `json:"enabled" gorm:"default:true;index"`
	Sort          int    `json:"sort" gorm:"default:0;index"`
}

func (BlogSkill) TableName() string { return "blog_skills" }

type BlogProject struct {
	global.GVA_MODEL
	Name          string         `json:"name" gorm:"size:180;not null"`
	DescriptionZh string         `json:"descriptionZh" gorm:"type:text"`
	DescriptionEn string         `json:"descriptionEn" gorm:"type:text"`
	Link          string         `json:"link" gorm:"size:1024"`
	Tags          datatypes.JSON `json:"tags" gorm:"type:json"`
	Enabled       bool           `json:"enabled" gorm:"default:true;index"`
	Sort          int            `json:"sort" gorm:"default:0;index"`
}

func (BlogProject) TableName() string { return "blog_projects" }

type BlogExperience struct {
	global.GVA_MODEL
	Period         string `json:"period" gorm:"size:64;not null"`
	TitleZh        string `json:"titleZh" gorm:"size:180;not null"`
	TitleEn        string `json:"titleEn" gorm:"size:180"`
	OrganizationZh string `json:"organizationZh" gorm:"size:180"`
	OrganizationEn string `json:"organizationEn" gorm:"size:180"`
	DescriptionZh  string `json:"descriptionZh" gorm:"type:text"`
	DescriptionEn  string `json:"descriptionEn" gorm:"type:text"`
	Enabled        bool   `json:"enabled" gorm:"default:true;index"`
	Sort           int    `json:"sort" gorm:"default:0;index"`
}

func (BlogExperience) TableName() string { return "blog_experiences" }
