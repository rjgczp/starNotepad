package starNote

import (
	"context"
	"fmt"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	"go.uber.org/zap"
	"gorm.io/gorm/clause"
)

const (
	autoTagAsyncTimeout = 8 * time.Second
)

func (stService *StarTagService) TriggerRefreshSimpleTagsAsync(ctx context.Context, userID uint) {
	stService.runAsync(ctx, userID, func(runCtx context.Context) {
		if err := stService.RefreshSimpleTags(runCtx, userID); err != nil {
			global.GVA_LOG.Error("refresh simple tags failed", zap.Uint("userID", userID), zap.Error(err))
		}
	})
}

func (stService *StarTagService) TriggerAfterNoteChangedAsync(ctx context.Context, userID uint) {
	stService.runAsync(ctx, userID, func(runCtx context.Context) {
		if err := stService.EvaluateAndAssignImplementedTags(runCtx, userID); err != nil {
			global.GVA_LOG.Error("evaluate tags after note change failed", zap.Uint("userID", userID), zap.Error(err))
		}
	})
}

func (stService *StarTagService) TriggerOnLoginSuccessAsync(ctx context.Context, userID uint) {
	stService.runAsync(ctx, userID, func(runCtx context.Context) {
		if err := stService.recordLogin(runCtx, userID, time.Now()); err != nil {
			global.GVA_LOG.Error("record login failed", zap.Uint("userID", userID), zap.Error(err))
		}
		if err := stService.EvaluateAndAssignImplementedTags(runCtx, userID); err != nil {
			global.GVA_LOG.Error("evaluate tags after login failed", zap.Uint("userID", userID), zap.Error(err))
		}
	})
}

func (stService *StarTagService) TriggerOnAIPolishSuccessAsync(ctx context.Context, userID uint) {
	stService.runAsync(ctx, userID, func(runCtx context.Context) {
		if err := stService.recordAIPolish(runCtx, userID); err != nil {
			global.GVA_LOG.Error("record AI polish failed", zap.Uint("userID", userID), zap.Error(err))
		}
		if err := stService.EvaluateAndAssignImplementedTags(runCtx, userID); err != nil {
			global.GVA_LOG.Error("evaluate tags after AI polish failed", zap.Uint("userID", userID), zap.Error(err))
		}
	})
}

func (stService *StarTagService) TriggerOnHistoryViewedAsync(ctx context.Context, userID uint) {
	stService.runAsync(ctx, userID, func(runCtx context.Context) {
		if err := stService.assignTag(runCtx, userID, starNote.TagIDTimeCollector); err != nil {
			global.GVA_LOG.Error("assign history-view tag failed", zap.Uint("userID", userID), zap.Error(err))
		}
	})
}

func (stService *StarTagService) runAsync(ctx context.Context, userID uint, fn func(runCtx context.Context)) {
	if userID == 0 || fn == nil || global.GVA_DB == nil {
		return
	}
	go func() {
		runCtx := context.Background()
		if ctx != nil {
			runCtx = ctx
		}
		c, cancel := context.WithTimeout(runCtx, autoTagAsyncTimeout)
		defer cancel()
		fn(c)
	}()
}

func (stService *StarTagService) RefreshSimpleTags(ctx context.Context, userID uint) error {
	if userID == 0 {
		return nil
	}
	results, err := stService.collectSimpleTagResults(ctx, userID)
	if err != nil {
		return err
	}
	for tagID, ok := range results {
		if ok {
			if err = stService.assignTag(ctx, userID, tagID); err != nil {
				return err
			}
		}
	}
	return nil
}

func (stService *StarTagService) EvaluateAndAssignImplementedTags(ctx context.Context, userID uint) error {
	if userID == 0 {
		return nil
	}
	results := map[uint]bool{}

	simpleResults, err := stService.collectSimpleTagResults(ctx, userID)
	if err != nil {
		return err
	}
	for tagID, ok := range simpleResults {
		results[tagID] = ok
	}

	if ok, e := stService.hitNoteMaster(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDNoteMaster] = ok
	}
	if ok, e := stService.hitStarTraveler(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDStarTraveler] = ok
	}
	if ok, e := stService.hitLifeRecorder(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDLifeRecorder] = ok
	}
	if ok, e := stService.hitInspirationCatcher(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDInspirationCatcher] = ok
	}
	if ok, e := stService.hitActiveMember(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDActiveMember] = ok
	}
	if ok, e := stService.hitMinimalist(ctx, userID); e != nil {
		return e
	} else {
		results[starNote.TagIDMinimalist] = ok
	}

	for tagID, ok := range results {
		if ok {
			if err = stService.assignTag(ctx, userID, tagID); err != nil {
				return err
			}
		}
	}
	return nil
}

func (stService *StarTagService) collectSimpleTagResults(ctx context.Context, userID uint) (map[uint]bool, error) {
	results := map[uint]bool{}
	if ok, err := stService.hitNewcomer(ctx, userID); err != nil {
		return nil, err
	} else {
		results[starNote.TagIDNewcomer] = ok
	}
	if ok, err := stService.hitVeteranUser(ctx, userID); err != nil {
		return nil, err
	} else {
		results[starNote.TagIDVeteranUser] = ok
	}
	if ok, err := stService.hitGoldCollector(ctx, userID); err != nil {
		return nil, err
	} else {
		results[starNote.TagIDGoldCollector] = ok
	}
	return results, nil
}

func (stService *StarTagService) assignTag(ctx context.Context, userID uint, tagID uint) error {
	if userID == 0 || tagID == 0 || global.GVA_DB == nil {
		return nil
	}
	ut := starNote.UserTag{UserID: userID, TagID: tagID}
	return global.GVA_DB.WithContext(ctx).Clauses(clause.OnConflict{DoNothing: true}).Create(&ut).Error
}

func (stService *StarTagService) recordLogin(ctx context.Context, userID uint, t time.Time) error {
	if userID == 0 || global.GVA_DB == nil {
		return nil
	}
	day := time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, t.Location())
	log := starNote.UserLoginLog{UserID: userID, LoginDate: day}
	return global.GVA_DB.WithContext(ctx).Clauses(clause.OnConflict{DoNothing: true}).Create(&log).Error
}

func (stService *StarTagService) recordAIPolish(ctx context.Context, userID uint) error {
	if userID == 0 || global.GVA_DB == nil {
		return nil
	}
	log := starNote.UserAIPolishLog{UserID: userID}
	return global.GVA_DB.WithContext(ctx).Create(&log).Error
}

func (stService *StarTagService) hitNewcomer(ctx context.Context, userID uint) (bool, error) {
	var count int64
	newFrom := time.Now().AddDate(0, 0, -7)
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).
		Where("id = ?", userID).
		Where("created_at >= ?", newFrom).
		Where("signature IS NOT NULL AND TRIM(signature) <> ''").
		Count(&count).Error
	return count > 0, err
}

func (stService *StarTagService) hitVeteranUser(ctx context.Context, userID uint) (bool, error) {
	var count int64
	before := time.Now().AddDate(0, -1, 0)
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).
		Where("id = ?", userID).
		Where("created_at <= ?", before).
		Count(&count).Error
	return count > 0, err
}

func (stService *StarTagService) hitGoldCollector(ctx context.Context, userID uint) (bool, error) {
	var count int64
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.NoteModel{}).
		Where("user_id = ?", int64(userID)).
		Count(&count).Error
	return count >= 500, err
}

func (stService *StarTagService) hitNoteMaster(ctx context.Context, userID uint) (bool, error) {
	var count int64
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.NoteModel{}).
		Where("user_id = ?", int64(userID)).
		Count(&count).Error
	return count > 100, err
}

func (stService *StarTagService) hitStarTraveler(ctx context.Context, userID uint) (bool, error) {
	var count int64
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAIPolishLog{}).
		Where("user_id = ?", userID).
		Count(&count).Error
	return count >= 1, err
}

func (stService *StarTagService) hitInspirationCatcher(ctx context.Context, userID uint) (bool, error) {
	var count int64
	err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAIPolishLog{}).
		Where("user_id = ?", userID).
		Count(&count).Error
	return count >= 10, err
}

func (stService *StarTagService) hitLifeRecorder(ctx context.Context, userID uint) (bool, error) {
	return stService.hasConsecutiveDaysBySQL(
		ctx,
		`SELECT DATE(COALESCE(recorded_at, created_at)) AS day
		 FROM notes
		 WHERE user_id = ?
		 GROUP BY DATE(COALESCE(recorded_at, created_at))
		 ORDER BY day DESC
		 LIMIT 90`,
		[]interface{}{int64(userID)},
		30,
	)
}

func (stService *StarTagService) hitActiveMember(ctx context.Context, userID uint) (bool, error) {
	return stService.hasConsecutiveDaysBySQL(
		ctx,
		`SELECT login_date AS day
		 FROM user_login_logs
		 WHERE user_id = ?
		 GROUP BY login_date
		 ORDER BY day DESC
		 LIMIT 30`,
		[]interface{}{userID},
		7,
	)
}

func (stService *StarTagService) hitMinimalist(ctx context.Context, userID uint) (bool, error) {
	type noteLenRow struct {
		ContentLen int `gorm:"column:content_len"`
	}
	var rows []noteLenRow
	err := global.GVA_DB.WithContext(ctx).Raw(
		`SELECT CHAR_LENGTH(COALESCE(content, '')) AS content_len
		 FROM notes
		 WHERE user_id = ?
		 ORDER BY COALESCE(recorded_at, created_at) DESC, id DESC
		 LIMIT 10`,
		int64(userID),
	).Scan(&rows).Error
	if err != nil {
		return false, err
	}
	if len(rows) < 10 {
		return false, nil
	}
	for _, row := range rows {
		if row.ContentLen > 100 {
			return false, nil
		}
	}
	return true, nil
}

func (stService *StarTagService) hasConsecutiveDaysBySQL(ctx context.Context, query string, args []interface{}, required int) (bool, error) {
	if required <= 1 {
		return true, nil
	}
	rows, err := global.GVA_DB.WithContext(ctx).Raw(query, args...).Rows()
	if err != nil {
		return false, err
	}
	defer rows.Close()

	dates := make([]time.Time, 0, required*2)
	for rows.Next() {
		var dayRaw interface{}
		if scanErr := rows.Scan(&dayRaw); scanErr != nil {
			return false, fmt.Errorf("scan day failed: %w", scanErr)
		}

		var day time.Time
		switch v := dayRaw.(type) {
		case time.Time:
			day = v
		case []byte:
			parsed, parseErr := time.Parse("2006-01-02", string(v))
			if parseErr != nil {
				return false, parseErr
			}
			day = parsed
		case string:
			parsed, parseErr := time.Parse("2006-01-02", v)
			if parseErr != nil {
				return false, parseErr
			}
			day = parsed
		default:
			return false, fmt.Errorf("unsupported day type: %T", dayRaw)
		}
		dates = append(dates, time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.Local))
	}
	if len(dates) < required {
		return false, nil
	}

	streak := 1
	for i := 1; i < len(dates); i++ {
		diffDays := int(dates[i-1].Sub(dates[i]).Hours() / 24)
		if diffDays == 1 {
			streak++
			if streak >= required {
				return true, nil
			}
			continue
		}
		if diffDays == 0 {
			continue
		}
		streak = 1
	}
	return false, nil
}
