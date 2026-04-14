
package starNote

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
)

type StarTagService struct {}
// CreateStarTag 创建用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService) CreateStarTag(ctx context.Context, st *starNote.StarTag) (err error) {
	err = global.GVA_DB.Create(st).Error
	return err
}

// DeleteStarTag 删除用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService)DeleteStarTag(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.StarTag{},"id = ?",ID).Error
	return err
}

// DeleteStarTagByIds 批量删除用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService)DeleteStarTagByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.StarTag{},"id in ?",IDs).Error
	return err
}

// UpdateStarTag 更新用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService)UpdateStarTag(ctx context.Context, st starNote.StarTag) (err error) {
	err = global.GVA_DB.Model(&starNote.StarTag{}).Where("id = ?",st.ID).Updates(&st).Error
	return err
}

// GetStarTag 根据ID获取用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService)GetStarTag(ctx context.Context, ID string) (st starNote.StarTag, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&st).Error
	return
}
// GetStarTagInfoList 分页获取用户标签记录
// Author [yourname](https://github.com/yourname)
func (stService *StarTagService)GetStarTagInfoList(ctx context.Context, info starNoteReq.StarTagSearch) (list []starNote.StarTag, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNote.StarTag{})
    var sts []starNote.StarTag
    // 如果有条件搜索 下方会自动创建搜索语句
    if len(info.CreatedAtRange) == 2 {
     db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
    }
    
	err = db.Count(&total).Error
	if err!=nil {
    	return
    }
        var OrderStr string
        orderMap := make(map[string]bool)
           orderMap["id"] = true
           orderMap["created_at"] = true
         	orderMap["name"] = true
         	orderMap["color"] = true
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

	err = db.Find(&sts).Error
	return  sts, total, err
}
func (stService *StarTagService)GetStarTagPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
