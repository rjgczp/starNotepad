package starNote

import (
	"context"
	"errors"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	"github.com/flipped-aurora/gin-vue-admin/server/service/system"
)

type HistoryDayService struct{}

// CreateHistoryDay 创建历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) CreateHistoryDay(ctx context.Context, hd *starNote.HistoryDay) (err error) {
	err = global.GVA_DB.Create(hd).Error
	return err
}

// DeleteHistoryDay 删除历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) DeleteHistoryDay(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.HistoryDay{}, "id = ?", ID).Error
	return err
}

// DeleteHistoryDayByIds 批量删除历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) DeleteHistoryDayByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.HistoryDay{}, "id in ?", IDs).Error
	return err
}

// UpdateHistoryDay 更新历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) UpdateHistoryDay(ctx context.Context, hd starNote.HistoryDay) (err error) {
	err = global.GVA_DB.Model(&starNote.HistoryDay{}).Where("id = ?", hd.ID).Updates(&hd).Error
	return err
}

// GetHistoryDay 根据ID获取历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) GetHistoryDay(ctx context.Context, ID string) (hd starNote.HistoryDay, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&hd).Error
	return
}

// GetHistoryDayInfoList 分页获取历史上的今天记录
// Author [yourname](https://github.com/yourname)
func (hdService *HistoryDayService) GetHistoryDayInfoList(ctx context.Context, info starNoteReq.HistoryDaySearch) (list []starNote.HistoryDay, total int64, err error) {
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
		db = db.Where("title LIKE ?", "%"+*info.Title+"%")
	}
	if info.Content != "" {
		// TODO 数据类型为复杂类型，请根据业务需求自行实现复杂类型的查询业务
	}
	err = db.Count(&total).Error
	if err != nil {
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
	return hds, total, err
}

// GetHistoryDayToday 获取今日历史上的今天（鉴权接口使用）
func (hdService *HistoryDayService) GetHistoryDayToday(ctx context.Context) (list []map[string]interface{}, err error) {
	now := time.Now()
	month := int(now.Month())
	day := now.Day()

	var hds []starNote.HistoryDay
	err = global.GVA_DB.
		Model(&starNote.HistoryDay{}).
		Where("month = ? AND day = ?", month, day).
		Order("weight desc").
		Order("year desc").
		Order("id desc").
		Find(&hds).Error

	if err != nil {
		return nil, err
	}

	// 获取 COFCD 字典配置
	typeMap := make(map[string]string)
	status := true
	sysDict, err := system.DictionaryServiceApp.GetSysDictionary("COFCD", 0, &status)
	if err == nil {
		// 构建字典映射
		for _, detail := range sysDict.SysDictionaryDetails {
			if detail.Label != "" && detail.Value != "" {
				typeMap[detail.Value] = detail.Label
			}
		}
	}

	// 转换数据格式
	result := make([]map[string]interface{}, len(hds))
	for i, hd := range hds {
		typeStr := "未知"
		if hd.Type != nil {
			if val, ok := typeMap[*hd.Type]; ok {
				typeStr = val
			}
		}

		result[i] = map[string]interface{}{
			"id":        hd.ID,
			"month":     hd.Month,
			"day":       hd.Day,
			"year":      hd.Year,
			"title":     hd.Title,
			"summary":   hd.Summary,
			"content":   hd.Content,
			"quote":     hd.Quote,
			"type":      typeStr,
			"weight":    hd.Weight,
			"coverImg":  hd.CoverImg,
			"createdAt": hd.CreatedAt,
			"updatedAt": hd.UpdatedAt,
		}
	}

	return result, nil
}

func (hdService *HistoryDayService) GetHistoryDayPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}

// GetHistoryDayFuture 获取未来50天的历史上的今天数据
func (hdService *HistoryDayService) GetHistoryDayFuture(ctx context.Context) (map[string]interface{}, error) {
	if global.GVA_DB == nil {
		return nil, errors.New("db not init")
	}

	// 获取 COFCD 字典配置
	typeMap := make(map[string]string)
	status := true
	sysDict, err := system.DictionaryServiceApp.GetSysDictionary("COFCD", 0, &status)
	if err == nil {
		// 构建字典映射
		for _, detail := range sysDict.SysDictionaryDetails {
			if detail.Label != "" && detail.Value != "" {
				typeMap[detail.Value] = detail.Label
			}
		}
	}

	// 获取未来50天的数据
	result := make(map[string]interface{})
	today := time.Now()
	data := make(map[string][]map[string]interface{})

	for i := 0; i < 50; i++ {
		date := today.AddDate(0, 0, i)
		month := int(date.Month())
		day := date.Day()
		dateStr := date.Format("2006-01-02")

		var hds []starNote.HistoryDay
		err := global.GVA_DB.
			Model(&starNote.HistoryDay{}).
			Where("month = ? AND day = ?", month, day).
			Order("weight desc").
			Order("year desc").
			Order("id desc").
			Find(&hds).Error

		if err != nil {
			continue
		}

		// 转换数据格式
		if len(hds) > 0 {
			dayData := make([]map[string]interface{}, len(hds))
			for j, hd := range hds {
				typeStr := "未知"
				if hd.Type != nil {
					if val, ok := typeMap[*hd.Type]; ok {
						typeStr = val
					}
				}

				dayData[j] = map[string]interface{}{
					"id":       hd.ID,
					"month":    hd.Month,
					"day":      hd.Day,
					"year":     hd.Year,
					"title":    hd.Title,
					"summary":  hd.Summary,
					"content":  hd.Content,
					"quote":    hd.Quote,
					"type":     typeStr,
					"weight":   hd.Weight,
					"coverImg": hd.CoverImg,
				}
			}
			data[dateStr] = dayData
		}
	}

	result["data"] = data
	result["generatedAt"] = today.Format("2006-01-02 15:04:05")
	result["days"] = 50

	return result, nil
}
