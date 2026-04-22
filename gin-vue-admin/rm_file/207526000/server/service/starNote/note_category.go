
package starNote

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
)

type NoteCategoryService struct {}
// CreateNoteCategory 创建记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService) CreateNoteCategory(ctx context.Context, nc *starNote.NoteCategory) (err error) {
	err = global.GVA_DB.Create(nc).Error
	return err
}

// DeleteNoteCategory 删除记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService)DeleteNoteCategory(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.NoteCategory{},"id = ?",ID).Error
	return err
}

// DeleteNoteCategoryByIds 批量删除记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService)DeleteNoteCategoryByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.NoteCategory{},"id in ?",IDs).Error
	return err
}

// UpdateNoteCategory 更新记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService)UpdateNoteCategory(ctx context.Context, nc starNote.NoteCategory) (err error) {
	err = global.GVA_DB.Model(&starNote.NoteCategory{}).Where("id = ?",nc.ID).Updates(&nc).Error
	return err
}

// GetNoteCategory 根据ID获取记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService)GetNoteCategory(ctx context.Context, ID string) (nc starNote.NoteCategory, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&nc).Error
	return
}
// GetNoteCategoryInfoList 分页获取记事本分类管理记录
// Author [yourname](https://github.com/yourname)
func (ncService *NoteCategoryService)GetNoteCategoryInfoList(ctx context.Context, info starNoteReq.NoteCategorySearch) (list []starNote.NoteCategory, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNote.NoteCategory{})
    var ncs []starNote.NoteCategory
    // 如果有条件搜索 下方会自动创建搜索语句
    if len(info.CreatedAtRange) == 2 {
     db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
    }
    
	err = db.Count(&total).Error
	if err!=nil {
    	return
    }

	if limit != 0 {
       db = db.Limit(limit).Offset(offset)
    }

	err = db.Find(&ncs).Error
	return  ncs, total, err
}
func (ncService *NoteCategoryService)GetNoteCategoryPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
