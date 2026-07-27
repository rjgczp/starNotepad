package starNote

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"math/big"
	"sort"
	"strings"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	emailPlugService "github.com/flipped-aurora/gin-vue-admin/server/plugin/email/service"
	"github.com/flipped-aurora/gin-vue-admin/server/utils"
	"github.com/google/uuid"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

type UserAccountService struct{}

type CodeSendResult struct {
	Code string
}

type userAcquiredTag struct {
	ID    uint   `gorm:"column:id"`
	Name  string `gorm:"column:name"`
	Color string `gorm:"column:color"`
}

const (
	userEmailCodeSceneRegister       = "register"
	userEmailCodeSceneLoginNewDevice = "login_new_device"
	userEmailCodeSceneChangePassword = "change_password"
	maxAccountsPerEmail              = 5
)

// CreateUserAccount 创建用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) CreateUserAccount(ctx context.Context, ua *starNote.UserAccount) (err error) {
	if ua != nil && ua.Password != nil && *ua.Password != "" {
		h := utils.BcryptHash(*ua.Password)
		ua.Password = &h
	}
	err = global.GVA_DB.Create(ua).Error
	return err
}

// DeleteUserAccount 删除用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) DeleteUserAccount(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.Delete(&starNote.UserAccount{}, "id = ?", ID).Error
	return err
}

// DeleteUserAccountByIds 批量删除用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) DeleteUserAccountByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.Delete(&[]starNote.UserAccount{}, "id in ?", IDs).Error
	return err
}

// UpdateUserAccount 更新用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) UpdateUserAccount(ctx context.Context, ua starNote.UserAccount) (err error) {
	if ua.Password != nil && *ua.Password != "" {
		h := utils.BcryptHash(*ua.Password)
		ua.Password = &h
	}
	err = global.GVA_DB.Model(&starNote.UserAccount{}).Where("id = ?", ua.ID).Updates(&ua).Error
	return err
}

func (uaService *UserAccountService) Login(ctx context.Context, info starNoteReq.UserAccountLogin) (ua starNote.UserAccount, err error) {
	if global.GVA_DB == nil {
		return ua, errors.New("db not init")
	}
	info.Username = strings.TrimSpace(info.Username)
	info.EmailPhone = strings.TrimSpace(info.EmailPhone)
	info.Password = strings.TrimSpace(info.Password)
	if info.Password == "" {
		return ua, errors.New("password required")
	}

	db := global.GVA_DB.Model(&starNote.UserAccount{})
	if info.Username != "" {
		err = db.Where("username = ?", info.Username).First(&ua).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return uaService.autoRegisterOnLogin(ctx, info)
		}
	} else if info.EmailPhone != "" {
		var cnt int64
		if err := db.Where("email_phone = ?", info.EmailPhone).Count(&cnt).Error; err != nil {
			return ua, err
		}
		if cnt > 1 {
			return ua, errors.New("emailPhone ambiguous")
		}
		err = db.Where("email_phone = ?", info.EmailPhone).First(&ua).Error
	} else {
		return ua, errors.New("username or emailPhone required")
	}
	if err != nil {
		return ua, err
	}
	if ua.Password == nil {
		return ua, errors.New("password not set")
	}
	hash := strings.TrimSpace(*ua.Password)
	if ok := utils.BcryptCheck(info.Password, hash); !ok {
		prefix := hash
		if len(prefix) > 12 {
			prefix = prefix[:12]
		}
		global.GVA_LOG.Warn("password incorrect", zap.String("username", info.Username), zap.Int("hashLen", len(hash)), zap.String("hashPrefix", prefix))
		return ua, errors.New("password incorrect")
	}
	return ua, nil
}

func (uaService *UserAccountService) autoRegisterOnLogin(ctx context.Context, info starNoteReq.UserAccountLogin) (ua starNote.UserAccount, err error) {
	username := info.Username
	emailPhone := info.EmailPhone
	if emailPhone == "" {
		emailPhone = username
	}
	password := info.Password
	nickname := username
	ua.Username = &username
	ua.EmailPhone = &emailPhone
	ua.Password = &password
	ua.Nickname = &nickname
	ua.Gender = "未知"

	if err = uaService.CreateUserAccount(ctx, &ua); err != nil {
		return ua, err
	}
	if info.DeviceID != "" {
		if e := uaService.markUserDeviceVerified(ctx, ua.ID, info.DeviceID); e != nil {
			global.GVA_LOG.Warn("mark login device verified failed", zap.Uint("userID", ua.ID), zap.String("deviceID", info.DeviceID), zap.Error(e))
		}
	}
	global.GVA_LOG.Info("auto register on login", zap.Uint("userID", ua.ID), zap.String("username", username))
	return ua, nil
}

func (uaService *UserAccountService) markUserDeviceVerified(ctx context.Context, userID uint, deviceID string) error {
	if deviceID == "" {
		return nil
	}
	return global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var device starNote.UserDevice
		e := tx.Where("user_id = ? AND device_id = ?", userID, deviceID).First(&device).Error
		if errors.Is(e, gorm.ErrRecordNotFound) {
			device = starNote.UserDevice{UserID: userID, DeviceID: deviceID, Verified: true}
			return tx.Create(&device).Error
		}
		if e != nil {
			return e
		}
		return tx.Model(&starNote.UserDevice{}).Where("id = ?", device.ID).Update("verified", true).Error
	})
}

func (uaService *UserAccountService) SendRegisterEmailCode(ctx context.Context, email string) (CodeSendResult, error) {
	result := CodeSendResult{}
	if global.GVA_DB == nil {
		return result, errors.New("db not init")
	}
	if email == "" {
		return result, errors.New("email required")
	}
	if !strings.Contains(email, "@") {
		return result, errors.New("email invalid")
	}

	code, err := uaService.generate6DigitCode()
	if err != nil {
		return result, err
	}

	subject := "验证码"
	body := fmt.Sprintf(`
<div style="background-color: #0d1117; color: #ffffff; padding: 40px; font-family: 'PingFang SC', 'Microsoft YaHei', sans-serif; border-radius: 12px; max-width: 500px; margin: 20px auto; border: 1px solid #30363d;">
    <h2 style="color: #58a6ff; margin-bottom: 20px; font-weight: 400;">✨ 星记事 · 身份校验</h2>
    <p style="font-size: 14px; color: #8b949e; line-height: 1.6;">星际旅行者，您好：</p>
    <p style="font-size: 14px; color: #8b949e; line-height: 1.6;">我们收到了您的安全请求，请在验证页面输入下方代码以完成身份确认：</p>
    <div style="background: linear-gradient(135deg, #1f6feb 0%%, #111d2c 100%%); padding: 20px; border-radius: 8px; text-align: center; margin: 30px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 12px; color: #ffffff; text-shadow: 0 0 10px rgba(88,166,255,0.5);">%s</span>
    </div>
    <p style="font-size: 12px; color: #6e7681; border-top: 1px solid #30363d; padding-top: 20px; margin-top: 20px;">
        ⚠️ 该验证码将在 <b>10 分钟</b> 后熄灭。如非本人操作，请忽略此邮件。<br>
        <span style="font-style: italic; margin-top: 10px; display: block;">—— 守护你的生活小细节</span>
    </p>
</div>
`, code)
	if global.GVA_CONFIG.Email.Pattern {
		if err := emailPlugService.ServiceGroupApp.SendEmail(email, subject, body); err != nil {
			return result, err
		}
	}

	expiresAt := time.Now().Add(10 * time.Minute)
	rec := starNote.UserEmailCode{
		Email:     email,
		Scene:     userEmailCodeSceneRegister,
		CodeHash:  utils.BcryptHash(code),
		ExpiresAt: expiresAt,
	}
	if err := global.GVA_DB.WithContext(ctx).Create(&rec).Error; err != nil {
		return result, err
	}
	result.Code = code
	if !global.GVA_CONFIG.Email.Pattern {
		global.GVA_LOG.Info("register verify code direct return mode", zap.String("email", email))
	}
	return result, nil
}

func (uaService *UserAccountService) verifyEmailCode(ctx context.Context, email, scene, code, challengeID, deviceID string) error {
	if email == "" {
		return errors.New("email required")
	}
	if code == "" {
		return errors.New("emailCode required")
	}
	if scene == "" {
		return errors.New("scene required")
	}

	now := time.Now()
	return global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var rec starNote.UserEmailCode
		db := tx.Model(&starNote.UserEmailCode{}).
			Where("email = ? AND scene = ? AND used_at IS NULL AND expires_at > ?", email, scene, now)
		if challengeID != "" {
			db = db.Where("challenge_id = ?", challengeID)
		}
		if deviceID != "" {
			db = db.Where("device_id = ?", deviceID)
		}
		if err := db.Order("id desc").First(&rec).Error; err != nil {
			return errors.New("emailCode invalid")
		}
		if rec.AttemptCount >= 5 {
			return errors.New("emailCode attempts exceeded")
		}
		if !utils.BcryptCheck(code, rec.CodeHash) {
			_ = tx.Model(&starNote.UserEmailCode{}).Where("id = ?", rec.ID).Update("attempt_count", gorm.Expr("attempt_count + 1")).Error
			return errors.New("emailCode invalid")
		}
		return tx.Model(&starNote.UserEmailCode{}).Where("id = ?", rec.ID).Updates(map[string]any{
			"used_at":       &now,
			"attempt_count": gorm.Expr("attempt_count + 1"),
		}).Error
	})
}

func (uaService *UserAccountService) LoginWithDevice(ctx context.Context, info starNoteReq.UserAccountLogin) (ua starNote.UserAccount, needEmailVerify bool, challengeID string, verifyCode string, err error) {
	ua, err = uaService.Login(ctx, info)
	if err != nil {
		return ua, false, "", "", err
	}
	if info.DeviceID == "" {
		return ua, false, "", "", errors.New("deviceId required")
	}

	var device starNote.UserDevice
	err = global.GVA_DB.WithContext(ctx).Where("user_id = ? AND device_id = ? AND verified = ?", ua.ID, info.DeviceID, true).First(&device).Error
	if err == nil {
		return ua, false, "", "", nil
	}
	if !errors.Is(err, gorm.ErrRecordNotFound) {
		return ua, false, "", "", err
	}

	needEmailVerify = true
	challengeID = uuid.NewString()
	verifyCode, err = uaService.sendNewDeviceLoginCode(ctx, ua, info.DeviceID, challengeID)
	if err != nil {
		return ua, false, "", "", err
	}
	return ua, needEmailVerify, challengeID, verifyCode, nil
}

func (uaService *UserAccountService) sendNewDeviceLoginCode(ctx context.Context, ua starNote.UserAccount, deviceID, challengeID string) (string, error) {
	if ua.EmailPhone == nil || *ua.EmailPhone == "" {
		return "", errors.New("emailPhone not set")
	}
	code, err := uaService.generate6DigitCode()
	if err != nil {
		return "", err
	}
	subject := "新设备登录验证码"
	body := fmt.Sprintf("<p>你正在新设备登录，验证码是：<b>%s</b></p><p>有效期 10 分钟。</p>", code)
	if global.GVA_CONFIG.Email.Pattern {
		if err := emailPlugService.ServiceGroupApp.SendEmail(*ua.EmailPhone, subject, body); err != nil {
			return "", err
		}
	}
	expiresAt := time.Now().Add(10 * time.Minute)
	rec := starNote.UserEmailCode{
		UserID:      ua.ID,
		Email:       *ua.EmailPhone,
		Scene:       userEmailCodeSceneLoginNewDevice,
		CodeHash:    utils.BcryptHash(code),
		ExpiresAt:   expiresAt,
		ChallengeID: challengeID,
		DeviceID:    deviceID,
	}
	if err := global.GVA_DB.WithContext(ctx).Create(&rec).Error; err != nil {
		return "", err
	}
	if !global.GVA_CONFIG.Email.Pattern {
		global.GVA_LOG.Info("new device verify code direct return mode", zap.Uint("userID", ua.ID), zap.String("deviceID", deviceID), zap.String("challengeID", challengeID))
	}
	return code, nil
}

func (uaService *UserAccountService) LoginVerify(ctx context.Context, req starNoteReq.LoginVerifyReq) (ua starNote.UserAccount, err error) {
	if global.GVA_DB == nil {
		return ua, errors.New("db not init")
	}
	if req.DeviceID == "" {
		return ua, errors.New("deviceId required")
	}

	var codeRec starNote.UserEmailCode
	now := time.Now()
	err = global.GVA_DB.WithContext(ctx).
		Where("scene = ? AND challenge_id = ? AND device_id = ? AND used_at IS NULL AND expires_at > ?", userEmailCodeSceneLoginNewDevice, req.ChallengeID, req.DeviceID, now).
		Order("id desc").First(&codeRec).Error
	if err != nil {
		return ua, errors.New("challenge invalid")
	}
	if err := uaService.verifyEmailCode(ctx, codeRec.Email, userEmailCodeSceneLoginNewDevice, req.EmailCode, req.ChallengeID, req.DeviceID); err != nil {
		return ua, err
	}

	err = global.GVA_DB.WithContext(ctx).Where("id = ?", codeRec.UserID).First(&ua).Error
	if err != nil {
		return ua, err
	}

	return ua, global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		var device starNote.UserDevice
		err := tx.Where("user_id = ? AND device_id = ?", ua.ID, req.DeviceID).First(&device).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			device = starNote.UserDevice{UserID: ua.ID, DeviceID: req.DeviceID, Verified: true}
			return tx.Create(&device).Error
		}
		if err != nil {
			return err
		}
		return tx.Model(&starNote.UserDevice{}).Where("id = ?", device.ID).Update("verified", true).Error
	})
}

func (uaService *UserAccountService) VerifyRegisterEmailCode(ctx context.Context, email, code string) error {
	return uaService.verifyEmailCode(ctx, email, userEmailCodeSceneRegister, code, "", "")
}

func (uaService *UserAccountService) generate6DigitCode() (string, error) {
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func (uaService *UserAccountService) SendChangePasswordEmailCode(ctx context.Context, req starNoteReq.SendChangePasswordEmailCodeReq) (CodeSendResult, error) {
	result := CodeSendResult{}
	if global.GVA_DB == nil {
		return result, errors.New("db not init")
	}
	if req.Username == "" && req.EmailPhone == "" {
		return result, errors.New("username or emailPhone required")
	}

	var ua starNote.UserAccount
	var err error
	if req.Username != "" {
		err = global.GVA_DB.WithContext(ctx).Where("username = ?", req.Username).First(&ua).Error
	} else {
		var cnt int64
		if err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).Where("email_phone = ?", req.EmailPhone).Count(&cnt).Error; err != nil {
			return result, err
		}
		if cnt > 1 {
			return result, errors.New("emailPhone ambiguous")
		}
		err = global.GVA_DB.WithContext(ctx).Where("email_phone = ?", req.EmailPhone).First(&ua).Error
	}
	if err != nil {
		return result, err
	}
	if ua.EmailPhone == nil || *ua.EmailPhone == "" {
		return result, errors.New("emailPhone not set")
	}
	if !strings.Contains(*ua.EmailPhone, "@") {
		return result, errors.New("emailPhone must be email")
	}

	code, err := uaService.generate6DigitCode()
	if err != nil {
		return result, err
	}
	subject := "修改密码验证码"
	body := fmt.Sprintf("<p>你正在修改密码，验证码是：<b>%s</b></p><p>有效期 10 分钟。</p>", code)
	if global.GVA_CONFIG.Email.Pattern {
		if err := emailPlugService.ServiceGroupApp.SendEmail(*ua.EmailPhone, subject, body); err != nil {
			return result, err
		}
	}

	expiresAt := time.Now().Add(10 * time.Minute)
	rec := starNote.UserEmailCode{
		Email:     *ua.EmailPhone,
		Scene:     userEmailCodeSceneChangePassword,
		CodeHash:  utils.BcryptHash(code),
		ExpiresAt: expiresAt,
		DeviceID:  req.DeviceID,
	}
	if err := global.GVA_DB.WithContext(ctx).Create(&rec).Error; err != nil {
		return result, err
	}
	result.Code = code
	if !global.GVA_CONFIG.Email.Pattern {
		global.GVA_LOG.Info("change password verify code direct return mode", zap.Uint("userID", ua.ID))
	}
	return result, nil
}

func (uaService *UserAccountService) ChangePassword(ctx context.Context, req starNoteReq.ChangePasswordReq) error {
	if global.GVA_DB == nil {
		return errors.New("db not init")
	}
	if req.Username == "" && req.EmailPhone == "" {
		return errors.New("username or emailPhone required")
	}
	if req.NewPassword == "" {
		return errors.New("newPassword required")
	}
	if req.EmailCode == "" {
		return errors.New("emailCode required")
	}
	if len(req.NewPassword) < 6 {
		return errors.New("newPassword too short")
	}

	var ua starNote.UserAccount
	var err error
	if req.Username != "" {
		err = global.GVA_DB.WithContext(ctx).Where("username = ?", req.Username).First(&ua).Error
	} else {
		var cnt int64
		if err := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).Where("email_phone = ?", req.EmailPhone).Count(&cnt).Error; err != nil {
			return err
		}
		if cnt > 1 {
			return errors.New("emailPhone ambiguous")
		}
		err = global.GVA_DB.WithContext(ctx).Where("email_phone = ?", req.EmailPhone).First(&ua).Error
	}
	if err != nil {
		return err
	}
	if ua.EmailPhone == nil || *ua.EmailPhone == "" {
		return errors.New("emailPhone not set")
	}

	if err := uaService.verifyEmailCode(ctx, *ua.EmailPhone, userEmailCodeSceneChangePassword, req.EmailCode, "", req.DeviceID); err != nil {
		return err
	}

	newHash := utils.BcryptHash(req.NewPassword)
	return global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).
		Where("id = ?", ua.ID).
		Update("password", newHash).Error
}

func (uaService *UserAccountService) Register(ctx context.Context, info starNoteReq.UserAccountRegister) (ua starNote.UserAccount, err error) {
	if global.GVA_DB == nil {
		return ua, errors.New("db not init")
	}
	if info.Username == "" {
		return ua, errors.New("username required")
	}
	if info.EmailPhone == "" {
		return ua, errors.New("emailPhone required")
	}
	if !strings.Contains(info.EmailPhone, "@") {
		return ua, errors.New("emailPhone must be email")
	}
	if info.Password == "" {
		return ua, errors.New("password required")
	}
	if info.EmailCode == "" {
		return ua, errors.New("emailCode required")
	}
	if err := uaService.VerifyRegisterEmailCode(ctx, info.EmailPhone, info.EmailCode); err != nil {
		return ua, err
	}

	var exist starNote.UserAccount
	if err := global.GVA_DB.Where("username = ?", info.Username).First(&exist).Error; err == nil {
		return ua, errors.New("username already exists")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		return ua, fmt.Errorf("check username failed: %w", err)
	}
	var emailCnt int64
	if err := global.GVA_DB.Model(&starNote.UserAccount{}).Where("email_phone = ?", info.EmailPhone).Count(&emailCnt).Error; err != nil {
		return ua, fmt.Errorf("check emailPhone failed: %w", err)
	}
	if emailCnt >= maxAccountsPerEmail {
		return ua, errors.New("emailPhone limit exceeded")
	}

	username := info.Username
	emailPhone := info.EmailPhone
	password := info.Password
	ua.Username = &username
	ua.EmailPhone = &emailPhone
	ua.Password = &password

	if info.Nickname != "" {
		n := info.Nickname
		ua.Nickname = &n
	}
	if info.Address != "" {
		a := info.Address
		ua.Address = &a
	}
	if info.Signature != "" {
		s := info.Signature
		ua.Signature = &s
	}
	if info.Avatar != "" {
		ua.Avatar = info.Avatar
	}
	if info.Gender != "" {
		ua.Gender = info.Gender
	}

	err = uaService.CreateUserAccount(ctx, &ua)
	if err != nil {
		return ua, err
	}
	_ = uaService.markUserDeviceVerified(ctx, ua.ID, info.DeviceID)
	return ua, nil
}

// GetUserAccount 根据ID获取用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) GetUserAccount(ctx context.Context, ID string) (ua starNote.UserAccount, err error) {
	err = global.GVA_DB.Where("id = ?", ID).First(&ua).Error
	return
}

func (uaService *UserAccountService) GetCurrentUserProfile(ctx context.Context, userID uint) (ua starNote.UserAccount, tags []starNote.BuiltinTagMeta, err error) {
	err = global.GVA_DB.WithContext(ctx).Where("id = ?", userID).First(&ua).Error
	if err != nil {
		return ua, nil, err
	}

	var tagRows []userAcquiredTag
	err = global.GVA_DB.WithContext(ctx).Model(&starNote.UserTag{}).
		Select("user_tags.tag_id as id, COALESCE(star_tags.name, '') as name, COALESCE(star_tags.color, '') as color").
		Joins("LEFT JOIN star_tags ON star_tags.id = user_tags.tag_id").
		Where("user_tags.user_id = ?", userID).
		Order("user_tags.created_at asc").
		Scan(&tagRows).Error
	if err != nil {
		return ua, nil, err
	}

	tags = make([]starNote.BuiltinTagMeta, 0, len(tagRows))
	for _, row := range tagRows {
		tag := starNote.BuiltinTagMeta{ID: row.ID, Name: row.Name, Color: row.Color}
		if tag.Name == "" || tag.Color == "" {
			if builtinTag, ok := starNote.GetBuiltinTagByID(row.ID); ok {
				if tag.Name == "" {
					tag.Name = builtinTag.Name
				}
				if tag.Color == "" {
					tag.Color = builtinTag.Color
				}
			}
		}
		tags = append(tags, tag)
	}

	return ua, tags, nil
}

func (uaService *UserAccountService) UpdateCurrentUserProfile(ctx context.Context, userID uint, req starNoteReq.UpdateCurrentUserProfileReq) error {
	updates := map[string]any{}
	if req.Username != nil {
		updates["username"] = *req.Username
	}
	if req.EmailPhone != nil {
		updates["email_phone"] = *req.EmailPhone
	}
	if req.Nickname != nil {
		updates["nickname"] = *req.Nickname
	}
	if req.Avatar != nil {
		updates["avatar"] = *req.Avatar
	}
	if req.Gender != nil {
		updates["gender"] = *req.Gender
	}
	if req.Address != nil {
		updates["address"] = *req.Address
	}
	if req.Signature != nil {
		updates["signature"] = *req.Signature
	}

	if len(updates) == 0 {
		return nil
	}

	result := global.GVA_DB.WithContext(ctx).Model(&starNote.UserAccount{}).Where("id = ?", userID).Updates(updates)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (uaService *UserAccountService) GetAdminTagDictionary(ctx context.Context) (tags []starNote.BuiltinTagMeta, err error) {
	builtinMap := make(map[uint]starNote.BuiltinTagMeta, len(starNote.BuiltinTagList))
	for _, item := range starNote.BuiltinTagList {
		builtinMap[item.ID] = item
	}

	var dbRows []userAcquiredTag
	err = global.GVA_DB.WithContext(ctx).Model(&starNote.StarTag{}).
		Select("id, COALESCE(name, '') as name, COALESCE(color, '') as color").
		Order("id asc").
		Scan(&dbRows).Error
	if err != nil {
		return nil, err
	}

	for _, row := range dbRows {
		tag := starNote.BuiltinTagMeta{ID: row.ID, Name: row.Name, Color: row.Color}
		if tag.Name == "" || tag.Color == "" {
			if builtinTag, ok := builtinMap[row.ID]; ok {
				if tag.Name == "" {
					tag.Name = builtinTag.Name
				}
				if tag.Color == "" {
					tag.Color = builtinTag.Color
				}
			}
		}
		builtinMap[row.ID] = tag
	}

	tags = make([]starNote.BuiltinTagMeta, 0, len(builtinMap))
	for _, tag := range builtinMap {
		tags = append(tags, tag)
	}
	sort.Slice(tags, func(i, j int) bool {
		return tags[i].ID < tags[j].ID
	})
	return tags, nil
}

func (uaService *UserAccountService) GetAdminUserTagIDs(ctx context.Context, userID uint) (tagIDs []uint, err error) {
	var user starNote.UserAccount
	if err = global.GVA_DB.WithContext(ctx).Select("id").Where("id = ?", userID).First(&user).Error; err != nil {
		return nil, err
	}

	err = global.GVA_DB.WithContext(ctx).Model(&starNote.UserTag{}).
		Where("user_id = ?", userID).
		Order("tag_id asc").
		Pluck("tag_id", &tagIDs).Error
	if err != nil {
		return nil, err
	}
	return tagIDs, nil
}

func (uaService *UserAccountService) ReplaceAdminUserTags(ctx context.Context, userID uint, tagIDs []uint) error {
	var user starNote.UserAccount
	if err := global.GVA_DB.WithContext(ctx).Select("id").Where("id = ?", userID).First(&user).Error; err != nil {
		return err
	}

	validTags, err := uaService.GetAdminTagDictionary(ctx)
	if err != nil {
		return err
	}
	validSet := make(map[uint]struct{}, len(validTags))
	for _, tag := range validTags {
		validSet[tag.ID] = struct{}{}
	}

	uniqIDs := make([]uint, 0, len(tagIDs))
	seen := make(map[uint]struct{}, len(tagIDs))
	for _, tagID := range tagIDs {
		if _, ok := validSet[tagID]; !ok {
			return fmt.Errorf("invalid tag id: %d", tagID)
		}
		if _, ok := seen[tagID]; ok {
			continue
		}
		seen[tagID] = struct{}{}
		uniqIDs = append(uniqIDs, tagID)
	}

	return global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if err := tx.Where("user_id = ?", userID).Delete(&starNote.UserTag{}).Error; err != nil {
			return err
		}

		if len(uniqIDs) == 0 {
			return nil
		}

		now := time.Now()
		relations := make([]starNote.UserTag, 0, len(uniqIDs))
		for _, tagID := range uniqIDs {
			relations = append(relations, starNote.UserTag{UserID: userID, TagID: tagID, CreatedAt: now})
		}

		return tx.Create(&relations).Error
	})
}

// GetUserAccountInfoList 分页获取用户账号记录
// Author [yourname](https://github.com/yourname)
func (uaService *UserAccountService) GetUserAccountInfoList(ctx context.Context, info starNoteReq.UserAccountSearch) (list []starNote.UserAccount, total int64, err error) {
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
	if err != nil {
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
	return uas, total, err
}
func (uaService *UserAccountService) GetUserAccountPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}
