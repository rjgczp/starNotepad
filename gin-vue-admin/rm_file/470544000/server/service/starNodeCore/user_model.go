
package starNodeCore

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNodeCore"
    starNodeCoreReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNodeCore/request"
)

type UserInfoService struct {}
// CreateUserInfo 创建用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService) CreateUserInfo(ctx context.Context, usr *starNodeCore.UserInfo) (err error) {
	err = global.GVA_DB.Create(usr).Error
	return err
}

// DeleteUserInfo 删除用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService)DeleteUserInfo(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNodeCore.UserInfo{},"id = ?",ID).Error
	return err
}

// DeleteUserInfoByIds 批量删除用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService)DeleteUserInfoByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNodeCore.UserInfo{},"id in ?",IDs).Error
	return err
}

// UpdateUserInfo 更新用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService)UpdateUserInfo(ctx context.Context, usr starNodeCore.UserInfo) (err error) {
	err = global.GVA_DB.Model(&starNodeCore.UserInfo{}).Where("id = ?",usr.ID).Updates(&usr).Error
	return err
}

// GetUserInfo 根据ID获取用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService)GetUserInfo(ctx context.Context, ID string) (usr starNodeCore.UserInfo, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&usr).Error
	return
}
// GetUserInfoInfoList 分页获取用户信息记录
// Author [yourname](https://github.com/yourname)
func (usrService *UserInfoService)GetUserInfoInfoList(ctx context.Context, info starNodeCoreReq.UserInfoSearch) (list []starNodeCore.UserInfo, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&starNodeCore.UserInfo{})
    var usrs []starNodeCore.UserInfo
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

	err = db.Find(&usrs).Error
	return  usrs, total, err
}
func (usrService *UserInfoService)GetUserInfoPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
