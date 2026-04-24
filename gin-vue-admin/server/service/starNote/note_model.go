package starNote

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"github.com/flipped-aurora/gin-vue-admin/server/utils/crypto"
	"gorm.io/gorm"
)

type NoteModelService struct{}

// CreateNoteModel 创建记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) CreateNoteModel(ctx context.Context, evt *starNote.NoteModel) (err error) {
	err = global.GVA_DB.Create(evt).Error
	return err
}

func (evtService *NoteModelService) CreateUserNoteModel(ctx context.Context, userID uint, evt *starNote.NoteModel) (err error) {
	if global.GVA_DB == nil {
		return errors.New("db not init")
	}
	uid := int64(userID)
	evt.UserID = &uid
	err = global.GVA_DB.Create(evt).Error
	return err
}

// DeleteNoteModel 删除记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) DeleteNoteModel(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.NoteModel{}, "id = ?", ID).Error
	return err
}

func (evtService *NoteModelService) DeleteUserNoteModel(ctx context.Context, userID uint, ID string) (err error) {
	if global.GVA_DB == nil {
		return errors.New("db not init")
	}
	uid := int64(userID)
	res := global.GVA_DB.Where("id = ? AND user_id = ?", ID, uid).Delete(&starNote.NoteModel{})
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// DeleteNoteModelByIds 批量删除记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) DeleteNoteModelByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.NoteModel{}, "id in ?", IDs).Error
	return err
}

// UpdateNoteModel 更新记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) UpdateNoteModel(ctx context.Context, evt starNote.NoteModel) (err error) {
	err = global.GVA_DB.Model(&starNote.NoteModel{}).Where("id = ?", evt.ID).Updates(&evt).Error
	return err
}

func (evtService *NoteModelService) UpdateUserNoteModel(ctx context.Context, userID uint, evt starNote.NoteModel) (err error) {
	if global.GVA_DB == nil {
		return errors.New("db not init")
	}
	uid := int64(userID)
	evt.UserID = &uid
	res := global.GVA_DB.Model(&starNote.NoteModel{}).Where("id = ? AND user_id = ?", evt.ID, uid).Updates(&evt)
	if res.Error != nil {
		return res.Error
	}
	if res.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

// GetNoteModel 根据ID获取记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) GetNoteModel(ctx context.Context, ID string) (evt starNote.NoteModel, err error) {
	err = global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteModel{}).
		Select("notes.*, sys_users.username as user_name").
		Joins("LEFT JOIN sys_users ON sys_users.id = notes.user_id").
		Where("notes.id = ?", ID).
		First(&evt).Error
	return
}

func (evtService *NoteModelService) GetUserNoteModel(ctx context.Context, userID uint, ID string) (evt starNote.NoteModel, err error) {
	if global.GVA_DB == nil {
		return evt, errors.New("db not init")
	}
	uid := int64(userID)
	err = global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteModel{}).
		Select("notes.*, sys_users.username as user_name").
		Joins("LEFT JOIN sys_users ON sys_users.id = notes.user_id").
		Where("notes.id = ? AND notes.user_id = ?", ID, uid).
		First(&evt).Error
	return evt, err
}

// GetNoteModelInfoList 分页获取记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) GetNoteModelInfoList(ctx context.Context, info starNoteReq.NoteModelSearch) (list []starNote.NoteModel, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	// 创建db
	db := global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteModel{}).
		Select("notes.*, sys_users.username as user_name").
		Joins("LEFT JOIN sys_users ON sys_users.id = notes.user_id")
	var evts []starNote.NoteModel
	// 如果有条件搜索 下方会自动创建搜索语句
	if len(info.CreatedAtRange) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
	}
	if strings.TrimSpace(info.UserName) != "" {
		db = db.Where("sys_users.username LIKE ?", "%"+strings.TrimSpace(info.UserName)+"%")
	}
	// 标题/正文已加密存储，无法使用 LIKE 模糊搜索，这里主动忽略以避免返回错误结果。

	err = db.Count(&total).Error
	if err != nil {
		return
	}

	if limit != 0 {
		db = db.Limit(limit).Offset(offset)
	}

	if err = db.Find(&evts).Error; err != nil {
		return evts, total, err
	}
	// 管理端列表不展示标题与正文（加密字段），直接置空，避免前端误用并降低泄露面。
	for i := range evts {
		evts[i].Title = nil
		evts[i].Content = nil
	}
	return evts, total, nil
}

func (evtService *NoteModelService) GetUserNoteModelInfoList(ctx context.Context, userID uint, info starNoteReq.NoteModelSearch) (list []starNote.NoteModel, total int64, err error) {
	if global.GVA_DB == nil {
		return nil, 0, errors.New("db not init")
	}
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	uid := int64(userID)
	db := global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteModel{}).
		Select("notes.*, sys_users.username as user_name").
		Joins("LEFT JOIN sys_users ON sys_users.id = notes.user_id").
		Where("notes.user_id = ?", uid)
	var evts []starNote.NoteModel
	if len(info.CreatedAtRange) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
	}
	if strings.TrimSpace(info.UserName) != "" {
		db = db.Where("sys_users.username LIKE ?", "%"+strings.TrimSpace(info.UserName)+"%")
	}
	if strings.TrimSpace(info.Title) != "" {
		db = db.Where("notes.title LIKE ?", "%"+strings.TrimSpace(info.Title)+"%")
	}
	if strings.TrimSpace(info.Content) != "" {
		db = db.Where("notes.content LIKE ?", "%"+strings.TrimSpace(info.Content)+"%")
	}

	err = db.Count(&total).Error
	if err != nil {
		return nil, 0, fmt.Errorf("count notes failed: %w", err)
	}
	if limit != 0 {
		db = db.Limit(limit).Offset(offset)
	}
	err = db.Find(&evts).Error
	return evts, total, err
}

func (evtService *NoteModelService) GetUserNoteModelAll(ctx context.Context, userID uint, page int, pageSize int, categoryID *int64) (list []starNote.NoteModel, total int64, err error) {
	if global.GVA_DB == nil {
		return nil, 0, errors.New("db not init")
	}
	if page <= 0 {
		page = 1
	}
	if pageSize < 0 {
		pageSize = 0
	}
	uid := int64(userID)
	var evts []starNote.NoteModel
	db := global.GVA_DB.WithContext(ctx).
		Model(&starNote.NoteModel{}).
		Select("notes.*, sys_users.username as user_name").
		Joins("LEFT JOIN sys_users ON sys_users.id = notes.user_id").
		Where("notes.user_id = ?", uid)

	// 如果传入了分类ID，则按分类过滤
	if categoryID != nil {
		db = db.Where("notes.category_id = ?", *categoryID)
	}

	err = db.Count(&total).Error
	if err != nil {
		return nil, 0, err
	}
	if pageSize != 0 {
		offset := pageSize * (page - 1)
		db = db.Limit(pageSize).Offset(offset)
	}
	err = db.Order("notes.id desc").Find(&evts).Error
	return evts, total, err
}
func (evtService *NoteModelService) GetNoteModelPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}

// GetNoteStatistics 获取用户记事本统计（按日期分组返回图标）
func (evtService *NoteModelService) GetNoteStatistics(ctx context.Context, userID uint) (map[string][]string, error) {
	if global.GVA_DB == nil {
		return nil, errors.New("db not init")
	}

	type DateIconResult struct {
		Date string `json:"date"`
		Icon string `json:"icon"`
	}

	var results []DateIconResult

	// 查询用户的所有记事本，按日期分组，获取图标
	err := global.GVA_DB.WithContext(ctx).
		Table("notes").
		Select("DATE(notes.created_at) as date, notes.icon").
		Where("notes.user_id = ? AND notes.icon IS NOT NULL AND notes.icon != ''", userID).
		Order("notes.created_at DESC").
		Scan(&results).Error

	if err != nil {
		return nil, err
	}

	// 按日期分组图标
	dateIcons := make(map[string][]string)
	for _, result := range results {
		if dateIcons[result.Date] == nil {
			dateIcons[result.Date] = []string{}
		}
		dateIcons[result.Date] = append(dateIcons[result.Date], result.Icon)
	}

	return dateIcons, nil
}

// GetNoteCalendar 获取用户日度记事本日历
func (evtService *NoteModelService) GetNoteCalendar(ctx context.Context, userID uint, date string) ([]map[string]interface{}, error) {
	if global.GVA_DB == nil {
		return nil, errors.New("db not init")
	}

	// 验证日期格式 (YYYY-MM-DD)
	if len(date) != 10 || date[4] != '-' || date[7] != '-' {
		return nil, errors.New("日期格式错误，应为 YYYY-MM-DD")
	}

	uid := int64(userID)

	// 查询指定日期的记事本
	type CalendarNote struct {
		ID        uint      `json:"id"`
		Title     string    `json:"title"`
		CreatedAt time.Time `json:"createdAt"`
		Icon      string    `json:"icon"`
	}

	var notes []CalendarNote
	err := global.GVA_DB.WithContext(ctx).
		Table("notes").
		Select("id, title, created_at, icon").
		Where("user_id = ? AND DATE(created_at) = ?", uid, date).
		Order("created_at ASC").
		Scan(&notes).Error

	if err != nil {
		return nil, err
	}

	// 转换为返回格式（title 字段因 Scan 未触发 GORM 钩子，此处手动解密以保证前端看到明文）
	result := make([]map[string]interface{}, len(notes))
	for i, note := range notes {
		title, _ := crypto.DecryptString(note.Title)
		result[i] = map[string]interface{}{
			"id":        note.ID,
			"title":     title,
			"createdAt": note.CreatedAt,
			"icon":      note.Icon,
		}
	}

	return result, nil
}

func (evtService *NoteModelService) SyncUserNotesPull(ctx context.Context, userID uint, lastSyncAt *time.Time) (notes []starNote.NoteModel, categories []starNote.NoteCategory, colors []starNote.StarColor, serverSyncAt time.Time, err error) {
	if global.GVA_DB == nil {
		return nil, nil, nil, time.Time{}, errors.New("db not init")
	}
	uid := int64(userID)
	serverSyncAt = time.Now()

	noteDB := global.GVA_DB.WithContext(ctx).
		Unscoped().
		Model(&starNote.NoteModel{}).
		Where("user_id = ?", uid)
	if lastSyncAt != nil {
		noteDB = noteDB.Where("updated_at > ? OR deleted_at > ?", *lastSyncAt, *lastSyncAt)
	}
	err = noteDB.Order("updated_at asc").Find(&notes).Error
	if err != nil {
		return nil, nil, nil, time.Time{}, err
	}

	categoryDB := global.GVA_DB.WithContext(ctx).
		Unscoped().
		Model(&starNote.NoteCategory{}).
		Where("user_id = ? OR user_id = 0", uid)
	if lastSyncAt != nil {
		categoryDB = categoryDB.Where("updated_at > ? OR deleted_at > ?", *lastSyncAt, *lastSyncAt)
	}
	err = categoryDB.Order("updated_at asc").Find(&categories).Error
	if err != nil {
		return nil, nil, nil, time.Time{}, err
	}

	colorDB := global.GVA_DB.WithContext(ctx).
		Unscoped().
		Model(&starNote.StarColor{}).
		Where("userid = ? OR userid = 0", uid)
	if lastSyncAt != nil {
		colorDB = colorDB.Where("updated_at > ? OR deleted_at > ?", *lastSyncAt, *lastSyncAt)
	}
	err = colorDB.Order("updated_at asc").Find(&colors).Error
	if err != nil {
		return nil, nil, nil, time.Time{}, err
	}

	return notes, categories, colors, serverSyncAt, nil
}

func (evtService *NoteModelService) SyncUserNotesPush(ctx context.Context, userID uint, req starNoteReq.UserNoteSyncPushReq) (serverSyncAt time.Time, err error) {
	if global.GVA_DB == nil {
		return time.Time{}, errors.New("db not init")
	}
	uid := int64(userID)
	notePayload := req.Notes
	if len(notePayload.Upserts) == 0 && len(notePayload.DeletedID) == 0 && (len(req.Upserts) > 0 || len(req.DeletedID) > 0) {
		notePayload.Upserts = req.Upserts
		notePayload.DeletedID = req.DeletedID
	}

	err = global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		for i := range notePayload.Upserts {
			note := notePayload.Upserts[i]
			note.UserName = nil
			note.UserID = &uid
			if note.ID == 0 {
				if err = tx.Create(&note).Error; err != nil {
					return err
				}
				continue
			}
			var exists starNote.NoteModel
			findErr := tx.Where("id = ? AND user_id = ?", note.ID, uid).First(&exists).Error
			if findErr != nil {
				if errors.Is(findErr, gorm.ErrRecordNotFound) {
					if err = tx.Create(&note).Error; err != nil {
						return err
					}
					continue
				}
				return findErr
			}
			if err = tx.Model(&starNote.NoteModel{}).Where("id = ? AND user_id = ?", note.ID, uid).Updates(&note).Error; err != nil {
				return err
			}
		}

		if len(notePayload.DeletedID) > 0 {
			if err = tx.Where("user_id = ? AND id in ?", uid, notePayload.DeletedID).Delete(&starNote.NoteModel{}).Error; err != nil {
				return err
			}
		}

		for i := range req.Categories.Upserts {
			category := req.Categories.Upserts[i]
			category.UserID = &uid
			if category.ID == 0 {
				if err = tx.Create(&category).Error; err != nil {
					return err
				}
				continue
			}
			var existsCategory starNote.NoteCategory
			findErr := tx.Where("id = ? AND user_id = ?", category.ID, uid).First(&existsCategory).Error
			if findErr != nil {
				if errors.Is(findErr, gorm.ErrRecordNotFound) {
					if err = tx.Create(&category).Error; err != nil {
						return err
					}
					continue
				}
				return findErr
			}
			if err = tx.Model(&starNote.NoteCategory{}).Where("id = ? AND user_id = ?", category.ID, uid).Updates(&category).Error; err != nil {
				return err
			}
		}

		if len(req.Categories.DeletedID) > 0 {
			if err = tx.Where("user_id = ? AND id in ?", uid, req.Categories.DeletedID).Delete(&starNote.NoteCategory{}).Error; err != nil {
				return err
			}
		}

		for i := range req.Colors.Upserts {
			color := req.Colors.Upserts[i]
			color.Userid = &uid
			if color.ID == 0 {
				if err = tx.Create(&color).Error; err != nil {
					return err
				}
				continue
			}
			var existsColor starNote.StarColor
			findErr := tx.Where("id = ? AND userid = ?", color.ID, uid).First(&existsColor).Error
			if findErr != nil {
				if errors.Is(findErr, gorm.ErrRecordNotFound) {
					if err = tx.Create(&color).Error; err != nil {
						return err
					}
					continue
				}
				return findErr
			}
			if err = tx.Model(&starNote.StarColor{}).Where("id = ? AND userid = ?", color.ID, uid).Updates(&color).Error; err != nil {
				return err
			}
		}

		if len(req.Colors.DeletedID) > 0 {
			if err = tx.Where("userid = ? AND id in ?", uid, req.Colors.DeletedID).Delete(&starNote.StarColor{}).Error; err != nil {
				return err
			}
		}

		return nil
	})
	if err != nil {
		return time.Time{}, err
	}

	return time.Now(), nil
}
