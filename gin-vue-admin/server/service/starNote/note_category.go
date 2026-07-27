package starNote

import (
	"context"
	"errors"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"gorm.io/gorm"
)

type NoteCategoryService struct{}

// CreateNoteCategory 创建记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) CreateNoteCategory(ctx context.Context, nc *starNote.NoteCategory) (err error) {
	err = global.GVA_DB.Create(nc).Error
	return err
}

// DeleteNoteCategory 删除记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) DeleteNoteCategory(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.NoteCategory{}, "id = ?", ID).Error
	return err
}

// DeleteNoteCategoryByIds 批量删除记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) DeleteNoteCategoryByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.NoteCategory{}, "id in ?", IDs).Error
	return err
}

// UpdateNoteCategory 更新记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) UpdateNoteCategory(ctx context.Context, nc starNote.NoteCategory) (err error) {
	err = global.GVA_DB.Model(&starNote.NoteCategory{}).Where("id = ?", nc.ID).Updates(&nc).Error
	return err
}

// GetNoteCategory 根据ID获取记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) GetNoteCategory(ctx context.Context, ID string) (nc starNote.NoteCategory, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&nc).Error
	return
}

// GetNoteCategoryInfoList 分页获取记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) GetNoteCategoryInfoList(ctx context.Context, info starNoteReq.NoteCategorySearch) (list []starNote.NoteCategory, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	// 创建db
	db := global.GVA_DB.Model(&starNote.NoteCategory{})
	var ncs []starNote.NoteCategory
	// 如果有条件搜索 下方会自动创建搜索语句
	if len(info.CreatedAtRange) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
	}

	if info.UserID != nil {
		db = db.Where("user_id = ?", *info.UserID)
	}
	err = db.Count(&total).Error
	if err != nil {
		return
	}

	if limit != 0 {
		db = db.Limit(limit).Offset(offset)
	}

	err = db.Find(&ncs).Error
	return ncs, total, err
}
func (ncService *NoteCategoryService) GetNoteCategoryPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}

func (ncService *NoteCategoryService) CreateUserNoteCategory(ctx context.Context, userID uint, name, color, icon string) (*starNote.NoteCategory, error) {
	uid := int64(userID)
	nc := &starNote.NoteCategory{}
	nc.UserID = &uid
	nc.Name = &name
	nc.Color = &color
	nc.Icon = &icon
	if err := global.GVA_DB.WithContext(ctx).Create(nc).Error; err != nil {
		return nil, err
	}
	return nc, nil
}

func (ncService *NoteCategoryService) GetUserNoteCategoryList(ctx context.Context, userID uint) ([]starNote.NoteCategory, error) {
	uid := int64(userID)
	var list []starNote.NoteCategory
	err := global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteCategory{}).
		Where("user_id = 0 OR user_id = ?", uid).
		Order("user_id asc").
		Order("id asc").
		Find(&list).Error
	if err != nil {
		return nil, err
	}
	return list, nil
}

func (ncService *NoteCategoryService) UpdateUserNoteCategory(ctx context.Context, userID uint, id uint, name, color, icon string) error {
	uid := int64(userID)
	var nc starNote.NoteCategory
	if err := global.GVA_DB.WithContext(ctx).Where("id = ?", id).First(&nc).Error; err != nil {
		return err
	}
	if nc.UserID == nil || *nc.UserID != uid {
		return gorm.ErrRecordNotFound
	}
	if *nc.UserID == 0 {
		return errors.New("system category not allowed")
	}
	updates := map[string]any{}
	if name != "" {
		updates["name"] = name
	}
	if color != "" {
		updates["color"] = color
	}
	if icon != "" {
		updates["icon"] = icon
	}
	if len(updates) == 0 {
		return nil
	}
	return global.GVA_DB.WithContext(ctx).Model(&starNote.NoteCategory{}).Where("id = ?", id).Updates(updates).Error
}

func (ncService *NoteCategoryService) DeleteUserNoteCategory(ctx context.Context, userID uint, id uint) error {
	uid := int64(userID)
	var nc starNote.NoteCategory
	if err := global.GVA_DB.WithContext(ctx).Where("id = ?", id).First(&nc).Error; err != nil {
		return err
	}
	if nc.UserID == nil || *nc.UserID != uid {
		return gorm.ErrRecordNotFound
	}
	if *nc.UserID == 0 {
		return errors.New("system category not allowed")
	}
	return global.GVA_DB.WithContext(ctx).Delete(&starNote.NoteCategory{}, "id = ?", id).Error
}
