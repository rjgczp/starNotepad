
package starNote

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
)

type HistoryDayService struct {}
// CreateHistoryDay 创建历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) CreateHistoryDay(ctx context.Context, hd *starNote.HistoryDay) (err error) {
	err = global.GVA_DB.Create(hd).Error
	return err
}

// DeleteHistoryDay 删除历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService)DeleteHistoryDay(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.HistoryDay{},"id = ?",ID).Error
	return err
}

// DeleteHistoryDayByIds 批量删除历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService)DeleteHistoryDayByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.HistoryDay{},"id in ?",IDs).Error
	return err
}

// UpdateHistoryDay 更新历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService)UpdateHistoryDay(ctx context.Context, hd starNote.HistoryDay) (err error) {
	err = global.GVA_DB.Model(&starNote.HistoryDay{}).Where("id = ?",hd.ID).Updates(&hd).Error
	return err
}

// GetHistoryDay 根据ID获取历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService)GetHistoryDay(ctx context.Context, ID string) (hd starNote.HistoryDay, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&hd).Error
	return
}
// GetHistoryDayInfoList 分页获取历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService)GetHistoryDayInfoList(ctx context.Context, info starNoteReq.HistoryDaySearch) (list []starNote.HistoryDay, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNote.HistoryDay{})
    var hds []starNote.HistoryDay
    // 如果有条件搜索 下方会自动创建搜索语句
    if len(info.CreatedAtRange) == 2 {
     db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
    }
    
    if info.Month != nil {
        db = db.Where("month = ?", *info.Month)
    }
    if info.Day != nil {
        db = db.Where("day = ?", *info.Day)
    }
    if info.Year != nil {
        db = db.Where("year = ?", *info.Year)
    }
    if info.Title != nil && *info.Title != "" {
        db = db.Where("title LIKE ?", "%"+ *info.Title+"%")
    }
    if info.Content != "" {
        // TODO 数据类型为复杂类型，请根据业务需求自行实现复杂类型的查询业务
    }
    if info.Type != "" {
        db = db.Where("type = ?", info.Type)
    }
	err = db.Count(&total).Error
	if err!=nil {
    	return
    }
        var OrderStr string
        orderMap := make(map[string]bool)
           orderMap["id"] = true
           orderMap["created_at"] = true
         	orderMap["month"] = true
         	orderMap["day"] = true
         	orderMap["year"] = true
         	orderMap["type"] = true
         	orderMap["weight"] = true
       if orderMap[info.Sort] {
          OrderStr = info.Sort
          if info.Order == "descending" {
             OrderStr = OrderStr + " desc"
          }
          db = db.Order(OrderStr)
       }

	if limit != 0 {
       db = db.Limit(limit).Offset(offset)
    }

	err = db.Find(&hds).Error
	return  hds, total, err
}
func (hdService *HistoryDayService)GetHistoryDayPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
