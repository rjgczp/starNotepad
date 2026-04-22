
package starNote

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
)

type NoteModelService struct {}
// CreateNoteModel 创建记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService) CreateNoteModel(ctx context.Context, evt *starNote.NoteModel) (err error) {
	err = global.GVA_DB.Create(evt).Error
	return err
}

// DeleteNoteModel 删除记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService)DeleteNoteModel(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.NoteModel{},"id = ?",ID).Error
	return err
}

// DeleteNoteModelByIds 批量删除记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService)DeleteNoteModelByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.NoteModel{},"id in ?",IDs).Error
	return err
}

// UpdateNoteModel 更新记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService)UpdateNoteModel(ctx context.Context, evt starNote.NoteModel) (err error) {
	err = global.GVA_DB.Model(&starNote.NoteModel{}).Where("id = ?",evt.ID).Updates(&evt).Error
	return err
}

// GetNoteModel 根据ID获取记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService)GetNoteModel(ctx context.Context, ID string) (evt starNote.NoteModel, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&evt).Error
	return
}
// GetNoteModelInfoList 分页获取记事本记录
// Author [yourname](https://github.com/yourname)
func (evtService *NoteModelService)GetNoteModelInfoList(ctx context.Context, info starNoteReq.NoteModelSearch) (list []starNote.NoteModel, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNote.NoteModel{})
    var evts []starNote.NoteModel
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

	err = db.Find(&evts).Error
	return  evts, total, err
}
func (evtService *NoteModelService)GetNoteModelPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
