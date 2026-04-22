
package starNote

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
    starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
)

type UserAccountService struct {}
// CreateUserAccount 创建用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) CreateUserAccount(ctx context.Context, ua *starNote.UserAccount) (err error) {
	err = global.GVA_DB.Create(ua).Error
	return err
}

// DeleteUserAccount 删除用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService)DeleteUserAccount(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.UserAccount{},"id = ?",ID).Error
	return err
}

// DeleteUserAccountByIds 批量删除用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService)DeleteUserAccountByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.UserAccount{},"id in ?",IDs).Error
	return err
}

// UpdateUserAccount 更新用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService)UpdateUserAccount(ctx context.Context, ua starNote.UserAccount) (err error) {
	err = global.GVA_DB.Model(&starNote.UserAccount{}).Where("id = ?",ua.ID).Updates(&ua).Error
	return err
}

// GetUserAccount 根据ID获取用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService)GetUserAccount(ctx context.Context, ID string) (ua starNote.UserAccount, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&ua).Error
	return
}
// GetUserAccountInfoList 分页获取用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService)GetUserAccountInfoList(ctx context.Context, info starNoteReq.UserAccountSearch) (list []starNote.UserAccount, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNote.UserAccount{})
    var uas []starNote.UserAccount
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
         	orderMap["username"] = true
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

	err = db.Find(&uas).Error
	return  uas, total, err
}
func (uaService *UserAccountService)GetUserAccountPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
