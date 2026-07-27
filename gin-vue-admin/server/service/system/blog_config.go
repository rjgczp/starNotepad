
package system

import (
	"context"
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
    systemReq "github.com/flipped-aurora/gin-vue-admin/server/model/system/request"
)

type UserBlog_configService struct {}
// CreateUserBlog_config 创建个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService) CreateUserBlog_config(ctx context.Context, bc *system.UserBlog_config) (err error) {
	err = global.GVA_DB.Create(bc).Error
	return err
}

// DeleteUserBlog_config 删除个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService)DeleteUserBlog_config(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&system.UserBlog_config{},"id = ?",ID).Error
	return err
}

// DeleteUserBlog_configByIds 批量删除个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService)DeleteUserBlog_configByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]system.UserBlog_config{},"id in ?",IDs).Error
	return err
}

// UpdateUserBlog_config 更新个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService)UpdateUserBlog_config(ctx context.Context, bc system.UserBlog_config) (err error) {
	err = global.GVA_DB.Model(&system.UserBlog_config{}).Where("id = ?",bc.ID).Updates(&bc).Error
	return err
}

// GetUserBlog_config 根据ID获取个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService)GetUserBlog_config(ctx context.Context, ID string) (bc system.UserBlog_config, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&bc).Error
	return
}
// GetUserBlog_configInfoList 分页获取个人主页记录
// Author [yourname](https://github.com/yourname)
func (bcService *UserBlog_configService)GetUserBlog_configInfoList(ctx context.Context, info systemReq.UserBlog_configSearch) (list []system.UserBlog_config, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
    // 创建db
	db := global.GVA_DB.Model(&system.UserBlog_config{})
    var bcs []system.UserBlog_config
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

	err = db.Find(&bcs).Error
	return  bcs, total, err
}
func (bcService *UserBlog_configService)GetUserBlog_configPublic(ctx context.Context) (bc system.UserBlog_config, err error) {
	err = global.GVA_DB.WithContext(ctx).
		Model(&system.UserBlog_config{}).
		Order("id desc").
		First(&bc).Error
	return bc, err
}
