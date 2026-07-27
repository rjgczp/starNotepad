package system

import (
	"context"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
)

type BlogContentService struct{}

func (s *BlogContentService) Public(ctx context.Context) (posts []system.BlogPost, skills []system.BlogSkill, projects []system.BlogProject, experiences []system.BlogExperience, err error) {
	db := global.GVA_DB.WithContext(ctx)
	if err = db.Where("published = ?", true).Order("published_at desc, sort asc, id desc").Find(&posts).Error; err != nil {
		return
	}
	if err = db.Where("enabled = ?", true).Order("sort asc, id asc").Find(&skills).Error; err != nil {
		return
	}
	if err = db.Where("enabled = ?", true).Order("sort asc, id asc").Find(&projects).Error; err != nil {
		return
	}
	err = db.Where("enabled = ?", true).Order("sort asc, id asc").Find(&experiences).Error
	return
}

func (s *BlogContentService) List(ctx context.Context) (posts []system.BlogPost, skills []system.BlogSkill, projects []system.BlogProject, experiences []system.BlogExperience, err error) {
	db := global.GVA_DB.WithContext(ctx)
	if err = db.Order("published_at desc, sort asc, id desc").Find(&posts).Error; err != nil {
		return
	}
	if err = db.Order("sort asc, id asc").Find(&skills).Error; err != nil {
		return
	}
	if err = db.Order("sort asc, id asc").Find(&projects).Error; err != nil {
		return
	}
	err = db.Order("sort asc, id asc").Find(&experiences).Error
	return
}
