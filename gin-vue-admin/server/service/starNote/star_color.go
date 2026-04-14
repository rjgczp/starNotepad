package starNote

import (
	"context"
	"errors"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"gorm.io/gorm"
)

type StarColorService struct{}

// CreateStarColor 创建星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) CreateStarColor(ctx context.Context, sc *starNote.StarColor) (err error) {
	err = global.GVA_DB.Create(sc).Error
	return err
}

// DeleteStarColor 删除星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) DeleteStarColor(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.StarColor{}, "id = ?", ID).Error
	return err
}

// DeleteStarColorByIds 批量删除星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) DeleteStarColorByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.StarColor{}, "id in ?", IDs).Error
	return err
}

// UpdateStarColor 更新星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) UpdateStarColor(ctx context.Context, sc starNote.StarColor) (err error) {
	err = global.GVA_DB.Model(&starNote.StarColor{}).Where("id = ?", sc.ID).Updates(&sc).Error
	return err
}

// GetStarColor 根据ID获取星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) GetStarColor(ctx context.Context, ID string) (sc starNote.StarColor, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&sc).Error
	return
}

// GetStarColorInfoList 分页获取星颜色记录
// Author [yourname](https://github.com/yourname)
func (scService *StarColorService) GetStarColorInfoList(ctx context.Context, info starNoteReq.StarColorSearch) (list []starNote.StarColor, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	// 创建db
	db := global.GVA_DB.Model(&starNote.StarColor{})
	var scs []starNote.StarColor
	// 如果有条件搜索 下方会自动创建搜索语句
	if len(info.CreatedAtRange) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
	}

	err = db.Count(&total).Error
	if err != nil {
		return
	}

	if limit != 0 {
		db = db.Limit(limit).Offset(offset)
	}

	err = db.Find(&scs).Error
	return scs, total, err
}
func (scService *StarColorService) GetStarColorPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}

func (scService *StarColorService) CreateUserStarColor(ctx context.Context, userID uint, name, color string) (*starNote.StarColor, error) {
	uid := int64(userID)
	sc := &starNote.StarColor{}
	sc.Userid = &uid
	sc.Colors = &name
	sc.Color = &color
	if err := global.GVA_DB.WithContext(ctx).Create(sc).Error; err != nil {
		return nil, err
	}
	return sc, nil
}

func (scService *StarColorService) GetUserStarColorList(ctx context.Context, userID uint) ([]starNote.StarColor, error) {
	uid := int64(userID)
	var list []starNote.StarColor
	err := global.GVA_DB.WithContext(ctx).
		Model(&starNote.StarColor{}).
		Where("userid = 0 OR userid = ?", uid).
		Order("userid asc").
		Order("id asc").
		Find(&list).Error
	if err != nil {
		return nil, err
	}
	return list, nil
}

func (scService *StarColorService) UpdateUserStarColor(ctx context.Context, userID uint, id uint, name, color string) error {
	uid := int64(userID)
	var sc starNote.StarColor
	if err := global.GVA_DB.WithContext(ctx).Where("id = ?", id).First(&sc).Error; err != nil {
		return err
	}
	if sc.Userid == nil || *sc.Userid != uid {
		return gorm.ErrRecordNotFound
	}
	if *sc.Userid == 0 {
		return errors.New("system color not allowed")
	}
	updates := map[string]any{}
	if name != "" {
		updates["colors"] = name
	}
	if color != "" {
		updates["color"] = color
	}
	if len(updates) == 0 {
		return nil
	}
	return global.GVA_DB.WithContext(ctx).Model(&starNote.StarColor{}).Where("id = ?", id).Updates(updates).Error
}

func (scService *StarColorService) DeleteUserStarColor(ctx context.Context, userID uint, id uint) error {
	uid := int64(userID)
	var sc starNote.StarColor
	if err := global.GVA_DB.WithContext(ctx).Where("id = ?", id).First(&sc).Error; err != nil {
		return err
	}
	if sc.Userid == nil || *sc.Userid != uid {
		return gorm.ErrRecordNotFound
	}
	if *sc.Userid == 0 {
		return errors.New("system color not allowed")
	}
	return global.GVA_DB.WithContext(ctx).Delete(&starNote.StarColor{}, "id = ?", id).Error
}
