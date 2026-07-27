package system

import (
	"context"
	"strings"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
)

type MainImageService struct{}

func normalizeMainImageURL(url string) string {
	url = strings.TrimSpace(url)
	if strings.HasPrefix(url, "/uploads/") {
		return "/api" + url
	}
	if strings.HasPrefix(url, "uploads/") {
		return "/api/" + url
	}
	if url == "" || strings.HasPrefix(url, "/") || strings.Contains(url, "://") || strings.HasPrefix(url, "data:") {
		return url
	}
	return "/" + url
}

func (s *MainImageService) List(ctx context.Context, publicOnly bool) (images []system.MainImage, err error) {
	db := global.GVA_DB.WithContext(ctx).Model(&system.MainImage{})
	if publicOnly {
		db = db.Where("enabled = ?", true)
	}
	err = db.Order("sort asc, id asc").Find(&images).Error
	return
}

func (s *MainImageService) Create(ctx context.Context, image *system.MainImage) error {
	image.URL = normalizeMainImageURL(image.URL)
	return global.GVA_DB.WithContext(ctx).Create(image).Error
}

func (s *MainImageService) Update(ctx context.Context, image system.MainImage) error {
	image.URL = normalizeMainImageURL(image.URL)
	return global.GVA_DB.WithContext(ctx).Model(&system.MainImage{}).Where("id = ?", image.ID).
		Updates(map[string]any{"name": image.Name, "url": image.URL, "sort": image.Sort, "enabled": image.Enabled}).Error
}

func (s *MainImageService) Delete(ctx context.Context, id uint) error {
	return global.GVA_DB.WithContext(ctx).Delete(&system.MainImage{}, id).Error
}
