
package User

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/User"
    UserReq "github.com/flipped-aurora/gin-vue-admin/server/model/User/request"
)

type UserInfoService struct {}
// CreateUserInfo 创建用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService) CreateUserInfo(ctx context.Context, user *User.UserInfo) (err error) {
	err = global.GVA_DB.Create(user).Error
	return err
}

// DeleteUserInfo 删除用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService)DeleteUserInfo(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&User.UserInfo{},"id = ?",ID).Error
	return err
}

// DeleteUserInfoByIds 批量删除用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService)DeleteUserInfoByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]User.UserInfo{},"id in ?",IDs).Error
	return err
}

// UpdateUserInfo 更新用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService)UpdateUserInfo(ctx context.Context, user User.UserInfo) (err error) {
	err = global.GVA_DB.Model(&User.UserInfo{}).Where("id = ?",user.ID).Updates(&user).Error
	return err
}

// GetUserInfo 根据ID获取用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService)GetUserInfo(ctx context.Context, ID string) (user User.UserInfo, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&user).Error
	return
}
// GetUserInfoInfoList 分页获取用户信息记录
// Author [yourname](https://github.com/yourname)
func (userService *UserInfoService)GetUserInfoInfoList(ctx context.Context, info UserReq.UserInfoSearch) (list []User.UserInfo, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&User.UserInfo{})
    var users []User.UserInfo
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

	err = db.Find(&users).Error
	return  users, total, err
}
func (userService *UserInfoService)GetUserInfoPublic(ctx context.Context) {
    // 此方法为获取数据源定义的数据
    // 请自行实现
}
