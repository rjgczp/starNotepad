
package mc

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/mc"
    mcReq "github.com/flipped-aurora/gin-vue-admin/server/model/mc/request"
)

type McWorldService struct {}
// CreateMcWorld 创建MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService) CreateMcWorld(ctx context.Context, mcworld *mc.McWorld) (err error) {
	err = global.GVA_DB.Create(mcworld).Error
	return err
}

// DeleteMcWorld 删除MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService)DeleteMcWorld(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&mc.McWorld{},"id = ?",ID).Error
	return err
}

// DeleteMcWorldByIds 批量删除MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService)DeleteMcWorldByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]mc.McWorld{},"id in ?",IDs).Error
	return err
}

// UpdateMcWorld 更新MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService)UpdateMcWorld(ctx context.Context, mcworld mc.McWorld) (err error) {
	err = global.GVA_DB.Model(&mc.McWorld{}).Where("id = ?",mcworld.ID).Updates(&mcworld).Error
	return err
}

// GetMcWorld 根据ID获取MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService)GetMcWorld(ctx context.Context, ID string) (mcworld mc.McWorld, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&mcworld).Error
	return
}
// GetMcWorldInfoList 分页获取MC世界记录
// Author [yourname](https://github.com/yourname)
func (mcworldService *McWorldService)GetMcWorldInfoList(ctx context.Context, info mcReq.McWorldSearch) (list []mc.McWorld, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&mc.McWorld{})
    var mcworlds []mc.McWorld
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
         	orderMap["slug"] = true
         	orderMap["world_path"] = true
         	orderMap["sort"] = true
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

	err = db.Find(&mcworlds).Error
	return  mcworlds, total, err
}
func (mcworldService *McWorldService)GetMcWorldPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
