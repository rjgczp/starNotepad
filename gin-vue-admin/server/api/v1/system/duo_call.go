package system

import (
	"crypto/subtle"
	"errors"
	"fmt"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	model "github.com/flipped-aurora/gin-vue-admin/server/model/system"
	serviceSystem "github.com/flipped-aurora/gin-vue-admin/server/service/system"
	"github.com/flipped-aurora/gin-vue-admin/server/utils/upload"
	"github.com/gin-gonic/gin"
	jwt "github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type DuoCallApi struct{}
type duoClaims struct {
	Slot       uint `json:"slot"`
	KeyVersion uint `json:"kv"`
	jwt.RegisteredClaims
}

type duoStatusView struct {
	ID    uint   `json:"ID"`
	Label string `json:"label"`
	Emoji string `json:"emoji"`
}

type duoIdentityView struct {
	Slot        uint           `json:"slot"`
	DisplayName string         `json:"displayName"`
	AvatarURL   string         `json:"avatarUrl"`
	StatusID    *uint          `json:"statusId"`
	Status      *duoStatusView `json:"status"`
}

type duoAppReleaseView struct {
	ID           uint       `json:"ID"`
	Platform     string     `json:"platform"`
	Version      string     `json:"version"`
	DownloadURL  string     `json:"downloadUrl"`
	ReleaseNotes string     `json:"releaseNotes"`
	ForceUpdate  bool       `json:"forceUpdate"`
	Published    bool       `json:"published"`
	PublishedAt  *time.Time `json:"publishedAt"`
}

var duoReleasePlatforms = map[string]bool{
	"web": true, "android": true, "desktop": true,
}

const duoReleaseMaxFileBytes int64 = 512 * 1024 * 1024

var duoReleaseExtensions = map[string]map[string]bool{
	"web":     {".zip": true, ".tar": true, ".gz": true},
	"android": {".apk": true, ".aab": true},
	"desktop": {".dmg": true, ".msi": true, ".exe": true, ".pkg": true, ".appimage": true, ".deb": true, ".rpm": true, ".zip": true},
}

func duoReleaseExtensionAllowed(platform, extension string) bool {
	return duoReleaseExtensions[platform][strings.ToLower(extension)]
}

func duoReleasePublicURL(value string) string {
	value = strings.TrimSpace(value)
	if !strings.HasPrefix(value, "/") {
		return value
	}
	base := strings.TrimRight(strings.TrimSpace(global.GVA_CONFIG.DuoRitual.PublicBaseURL), "/")
	if base == "" {
		return value
	}
	return base + value
}

func duoReleaseView(item model.DuoAppRelease) duoAppReleaseView {
	return duoAppReleaseView{
		ID: item.ID, Platform: item.Platform, Version: item.Version,
		DownloadURL: item.DownloadURL, ReleaseNotes: item.ReleaseNotes,
		ForceUpdate: item.ForceUpdate, Published: item.Published,
		PublishedAt: item.PublishedAt,
	}
}

// duoNormalizedVersion accepts the semantic version forms that the packaged
// clients expose (for example 1.2.0 or v1.2.0-beta.1) and rejects ambiguous
// release labels before they reach the update feed.
func duoNormalizedVersion(value string) (string, error) {
	value = strings.TrimPrefix(strings.TrimSpace(value), "v")
	if value == "" {
		return "", errors.New("版本号不能为空")
	}
	parts := strings.SplitN(value, "+", 2)
	main := parts[0]
	build := ""
	if len(parts) == 2 {
		build = parts[1]
		if !duoVersionIdentifiersValid(build) {
			return "", errors.New("版本号格式不正确")
		}
	}
	mainParts := strings.SplitN(main, "-", 2)
	core := strings.Split(mainParts[0], ".")
	if len(core) < 1 || len(core) > 3 {
		return "", errors.New("版本号格式不正确")
	}
	for len(core) < 3 {
		core = append(core, "0")
	}
	for _, part := range core {
		if part == "" {
			return "", errors.New("版本号格式不正确")
		}
		for _, character := range part {
			if character < '0' || character > '9' {
				return "", errors.New("版本号格式不正确")
			}
		}
	}
	normalized := strings.Join(core, ".")
	if len(mainParts) == 2 {
		if !duoVersionIdentifiersValid(mainParts[1]) {
			return "", errors.New("版本号格式不正确")
		}
		normalized += "-" + mainParts[1]
	}
	if build != "" {
		normalized += "+" + build
	}
	return normalized, nil
}

func duoVersionIdentifiersValid(value string) bool {
	if value == "" {
		return false
	}
	for _, part := range strings.Split(value, ".") {
		if part == "" {
			return false
		}
		for _, character := range part {
			if !(character >= 'a' && character <= 'z') &&
				!(character >= 'A' && character <= 'Z') &&
				!(character >= '0' && character <= '9') && character != '-' {
				return false
			}
		}
	}
	return true
}

// duoCompareVersions returns -1, 0, or 1. Build metadata is intentionally
// ignored, matching semantic-version precedence rules.
func duoCompareVersions(left, right string) (int, error) {
	left, err := duoNormalizedVersion(left)
	if err != nil {
		return 0, err
	}
	right, err = duoNormalizedVersion(right)
	if err != nil {
		return 0, err
	}
	leftMain := strings.SplitN(strings.SplitN(left, "+", 2)[0], "-", 2)
	rightMain := strings.SplitN(strings.SplitN(right, "+", 2)[0], "-", 2)
	for index, segment := range strings.Split(leftMain[0], ".") {
		leftNumber, _ := strconv.Atoi(segment)
		rightNumber, _ := strconv.Atoi(strings.Split(rightMain[0], ".")[index])
		if leftNumber < rightNumber {
			return -1, nil
		}
		if leftNumber > rightNumber {
			return 1, nil
		}
	}
	leftPrerelease := ""
	rightPrerelease := ""
	if len(leftMain) == 2 {
		leftPrerelease = leftMain[1]
	}
	if len(rightMain) == 2 {
		rightPrerelease = rightMain[1]
	}
	if leftPrerelease == "" && rightPrerelease != "" {
		return 1, nil
	}
	if leftPrerelease != "" && rightPrerelease == "" {
		return -1, nil
	}
	if leftPrerelease == rightPrerelease {
		return 0, nil
	}
	leftParts := strings.Split(leftPrerelease, ".")
	rightParts := strings.Split(rightPrerelease, ".")
	for index := 0; index < len(leftParts) && index < len(rightParts); index++ {
		if leftParts[index] == rightParts[index] {
			continue
		}
		leftNumber, leftNumeric := duoVersionNumber(leftParts[index])
		rightNumber, rightNumeric := duoVersionNumber(rightParts[index])
		if leftNumeric && rightNumeric {
			if leftNumber < rightNumber {
				return -1, nil
			}
			return 1, nil
		}
		if leftNumeric != rightNumeric {
			if leftNumeric {
				return -1, nil
			}
			return 1, nil
		}
		if leftParts[index] < rightParts[index] {
			return -1, nil
		}
		return 1, nil
	}
	if len(leftParts) < len(rightParts) {
		return -1, nil
	}
	return 1, nil
}

func duoVersionNumber(value string) (int, bool) {
	if value == "" {
		return 0, false
	}
	for _, character := range value {
		if character < '0' || character > '9' {
			return 0, false
		}
	}
	result, err := strconv.Atoi(value)
	return result, err == nil
}

func duoProfileName(value string) (string, error) {
	value = strings.TrimSpace(value)
	length := len([]rune(value))
	if length < 1 || length > 24 {
		return "", errors.New("昵称需要在 1 到 24 个字内")
	}
	return value, nil
}

func duoStatusMap(items []model.DuoCallStatus) map[uint]model.DuoCallStatus {
	result := make(map[uint]model.DuoCallStatus, len(items))
	for _, item := range items {
		result[item.ID] = item
	}
	return result
}

func duoIdentitySafeView(identity model.DuoCallIdentity, statuses map[uint]model.DuoCallStatus) duoIdentityView {
	view := duoIdentityView{
		Slot: identity.Slot, DisplayName: identity.DisplayName,
		AvatarURL: duoMediaURL(identity.AvatarURL), StatusID: identity.StatusID,
	}
	if identity.StatusID != nil {
		if status, ok := statuses[*identity.StatusID]; ok {
			view.Status = &duoStatusView{ID: status.ID, Label: status.Label, Emoji: status.Emoji}
		}
	}
	return view
}

func duoIdentityViewForSlot(slot uint) (duoIdentityView, error) {
	var identity model.DuoCallIdentity
	if err := global.GVA_DB.First(&identity, "slot = ?", slot).Error; err != nil {
		return duoIdentityView{}, err
	}
	var statuses []model.DuoCallStatus
	global.GVA_DB.Find(&statuses)
	return duoIdentitySafeView(identity, duoStatusMap(statuses)), nil
}

// duoMediaURL returns a same-origin root-relative media path. Media is served
// outside the JSON router prefix in both the development proxy and nginx.
func duoMediaURL(value string) string {
	if value == "" || strings.HasPrefix(value, "http://") || strings.HasPrefix(value, "https://") || strings.HasPrefix(value, "//") {
		return value
	}
	value = "/" + strings.TrimLeft(value, "/")
	apiUploads := "/" + strings.Trim(global.GVA_CONFIG.System.RouterPrefix, "/") + "/uploads/"
	if strings.HasPrefix(value, apiUploads) {
		value = "/uploads/" + strings.TrimPrefix(value, apiUploads)
	}
	if strings.HasPrefix(value, "/uploads/") {
		return value
	}
	storePath := strings.Trim(global.GVA_CONFIG.Local.StorePath, "/")
	if strings.HasPrefix(value, "/"+storePath+"/") {
		return value
	}
	return value
}

func duoJWTSecret() []byte {
	if v := os.Getenv("DUO_CALL_JWT_SECRET"); v != "" {
		return []byte(v)
	}
	return []byte("change-this-duo-call-jwt-secret")
}
func duoToken(slot, version uint) (string, error) {
	return jwt.NewWithClaims(jwt.SigningMethodHS256, duoClaims{Slot: slot, KeyVersion: version, RegisteredClaims: jwt.RegisteredClaims{ExpiresAt: jwt.NewNumericDate(time.Now().Add(30 * 24 * time.Hour)), IssuedAt: jwt.NewNumericDate(time.Now())}}).SignedString(duoJWTSecret())
}
func duoSession(c *gin.Context) (*duoClaims, error) {
	raw := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
	if raw == "" {
		raw = c.Query("token") // Browsers cannot attach Authorization to WebSocket upgrades.
	}
	token, err := jwt.ParseWithClaims(raw, &duoClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid token")
		}
		return duoJWTSecret(), nil
	})
	if err != nil || !token.Valid {
		return nil, errors.New("invalid session")
	}
	return token.Claims.(*duoClaims), nil
}
func duoAuth(c *gin.Context) (*duoClaims, bool) {
	claims, err := duoSession(c)
	if err != nil {
		response.FailWithDetailed(gin.H{"status": http.StatusUnauthorized}, "会话已失效", c)
		return nil, false
	}
	var identity model.DuoCallIdentity
	if global.GVA_DB.First(&identity, "slot = ?", claims.Slot).Error != nil || !identity.Enabled || identity.KeyVersion != claims.KeyVersion {
		response.FailWithDetailed(gin.H{"status": http.StatusUnauthorized}, "会话已失效", c)
		return nil, false
	}
	return claims, true
}

func duoQixiInvitationForSlot(slot uint) bool {
	configured := strings.TrimSpace(os.Getenv("DUO_QIXI_INVITATION_SLOT"))
	if configured == "" {
		return false
	}
	target, err := strconv.ParseUint(configured, 10, 64)
	return err == nil && target > 0 && slot == uint(target)
}

func (a *DuoCallApi) Login(c *gin.Context) {
	const maxLoginBodyBytes = 4 << 10
	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, maxLoginBodyBytes)
	var body struct {
		Key string `json:"key"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			c.AbortWithStatusJSON(http.StatusRequestEntityTooLarge, gin.H{
				"code": 7,
				"data": gin.H{},
				"msg":  "请求体过大",
			})
			return
		}
		response.FailWithMessage("请输入秘钥", c)
		return
	}
	if strings.TrimSpace(body.Key) == "" {
		response.FailWithMessage("请输入秘钥", c)
		return
	}
	var items []model.DuoCallIdentity
	global.GVA_DB.Where("enabled = ?", true).Find(&items)
	for _, item := range items {
		plain, err := duoCallService.DecryptKey(item.EncryptedKey)
		if err == nil && subtle.ConstantTimeCompare([]byte(plain), []byte(body.Key)) == 1 {
			token, err := duoToken(item.Slot, item.KeyVersion)
			if err != nil {
				response.FailWithMessage("登录失败", c)
				return
			}
			response.OkWithData(gin.H{
				"token": token, "slot": item.Slot, "displayName": item.DisplayName,
				"qixiInvitation": duoQixiInvitationForSlot(item.Slot),
			}, c)
			return
		}
	}
	response.FailWithMessage("秘钥不正确或未启用", c)
}
func (a *DuoCallApi) Bootstrap(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var identities []model.DuoCallIdentity
	var statuses []model.DuoCallStatus
	global.GVA_DB.Order("slot").Find(&identities)
	global.GVA_DB.Where("enabled = ?", true).Order("sort").Find(&statuses)
	statusMap := duoStatusMap(statuses)
	safeIdentities := make([]duoIdentityView, 0, len(identities))
	for _, identity := range identities {
		safeIdentities = append(safeIdentities, duoIdentitySafeView(identity, statusMap))
	}
	data := gin.H{"me": claims.Slot, "identities": safeIdentities, "statuses": statuses}
	turnHost := strings.TrimSpace(os.Getenv("DUO_TURN_HOST"))
	turnUsername := os.Getenv("DUO_TURN_USERNAME")
	turnPassword := os.Getenv("DUO_TURN_PASSWORD")
	if turnHost != "" && turnUsername != "" && turnPassword != "" {
		data["iceServers"] = []gin.H{
			{"urls": "stun:" + turnHost + ":3478"},
			{"urls": []string{"turn:" + turnHost + ":3478?transport=udp", "turn:" + turnHost + ":3478?transport=tcp"}, "username": turnUsername, "credential": turnPassword},
		}
	}
	response.OkWithData(data, c)
}

func (a *DuoCallApi) UpdateProfile(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var body struct {
		DisplayName string `json:"displayName"`
		StatusID    *uint  `json:"statusId"`
	}
	if c.ShouldBindJSON(&body) != nil {
		response.FailWithMessage("资料格式不正确", c)
		return
	}
	displayName, err := duoProfileName(body.DisplayName)
	if err != nil {
		response.FailWithMessage(err.Error(), c)
		return
	}
	var statusID *uint
	if body.StatusID != nil && *body.StatusID != 0 {
		var status model.DuoCallStatus
		if global.GVA_DB.First(&status, "id = ? AND enabled = ?", *body.StatusID, true).Error != nil {
			response.FailWithMessage("状态不可用", c)
			return
		}
		value := status.ID
		statusID = &value
	}
	result := global.GVA_DB.Model(&model.DuoCallIdentity{}).
		Where("slot = ?", claims.Slot).
		Updates(map[string]any{"display_name": displayName, "status_id": statusID})
	if result.Error != nil || result.RowsAffected != 1 {
		response.FailWithMessage("保存资料失败", c)
		return
	}
	view, err := duoIdentityViewForSlot(claims.Slot)
	if err != nil {
		response.FailWithMessage("读取资料失败", c)
		return
	}
	duoBroadcastEvent("profile", view)
	response.OkWithData(view, c)
}

func (a *DuoCallApi) UploadAvatar(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	file, err := c.FormFile("file")
	if err != nil || file.Size == 0 || file.Size > 5*1024*1024 {
		response.FailWithMessage("头像图片需小于 5MB", c)
		return
	}
	if !strings.HasPrefix(strings.ToLower(file.Header.Get("Content-Type")), "image/") {
		response.FailWithMessage("仅支持图片头像", c)
		return
	}
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true}
	if !allowed[ext] {
		response.FailWithMessage("头像格式不支持", c)
		return
	}
	var identity model.DuoCallIdentity
	if global.GVA_DB.First(&identity, "slot = ?", claims.Slot).Error != nil {
		response.FailWithMessage("成员不存在", c)
		return
	}
	previousAvatarURL := identity.AvatarURL
	dir := filepath.Join(duoStoreRoot(), "duo-call", "avatar")
	if err = os.MkdirAll(dir, 0755); err != nil {
		response.FailWithMessage("创建头像目录失败", c)
		return
	}
	name := uuid.NewString() + ext
	path := filepath.Join(dir, name)
	if err = c.SaveUploadedFile(file, path); err != nil {
		response.FailWithMessage("保存头像失败", c)
		return
	}
	avatarURL := "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/avatar/" + name
	if err = global.GVA_DB.Model(&identity).Update("avatar_url", avatarURL).Error; err != nil {
		_ = os.Remove(path)
		response.FailWithMessage("更新头像失败", c)
		return
	}
	removeDuoAvatarFile(previousAvatarURL)
	view, err := duoIdentityViewForSlot(claims.Slot)
	if err != nil {
		response.FailWithMessage("读取头像失败", c)
		return
	}
	duoBroadcastEvent("profile", view)
	response.OkWithData(view, c)
}

func removeDuoAvatarFile(url string) {
	prefix := "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/avatar/"
	if !strings.HasPrefix(url, prefix) {
		return
	}
	_ = os.Remove(filepath.Join(
		duoStoreRoot(), "duo-call", "avatar", filepath.Base(url),
	))
}

// duoStoreRoot resolves relative upload storage beside the running server binary
// when it is deployed in the release image. The container mounts uploads there,
// whereas a process working directory is not guaranteed after a restart.
func duoStoreRoot() string {
	storePath := filepath.Clean(global.GVA_CONFIG.Local.StorePath)
	if filepath.IsAbs(storePath) {
		return storePath
	}
	if executable, err := os.Executable(); err == nil {
		candidate := filepath.Join(filepath.Dir(executable), storePath)
		if info, statErr := os.Stat(filepath.Join(filepath.Dir(executable), "uploads")); statErr == nil && info.IsDir() {
			return candidate
		}
	}
	if absolute, err := filepath.Abs(storePath); err == nil {
		return absolute
	}
	return storePath
}

func (a *DuoCallApi) History(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "20"))
	if limit < 1 || limit > 20 {
		limit = 20
	}
	beforeID, _ := strconv.ParseUint(c.Query("beforeId"), 10, 64)
	var messages []model.DuoCallMessage
	query := global.GVA_DB.Order("id desc").Limit(limit + 1)
	if beforeID > 0 {
		query = query.Where("id < ?", beforeID)
	}
	query.Find(&messages)
	hasMore := len(messages) > limit
	if hasMore {
		messages = messages[:limit]
	}
	for i := range messages {
		messages[i].ImageURL = duoMediaURL(messages[i].ImageURL)
	}
	response.OkWithData(gin.H{"items": messages, "hasMore": hasMore}, c)
}

func duoPartnerSlot(slot uint) uint {
	if slot == 1 {
		return 2
	}
	return 1
}

func duoChatWechatEnabled(recipient model.DuoWechatRecipient) bool {
	return recipient.Enabled &&
		recipient.EncryptedOpenID != "" &&
		recipient.ChatMode != model.DuoPushModeDisabled
}

func (a *DuoCallApi) ChatWechatPreference(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	partnerSlot := duoPartnerSlot(claims.Slot)
	var recipient model.DuoWechatRecipient
	_ = global.GVA_DB.Where("slot = ?", partnerSlot).First(&recipient).Error
	response.OkWithData(gin.H{
		"enabled":       duoChatWechatEnabled(recipient),
		"partnerOnline": duoSocketHub.online(partnerSlot),
	}, c)
}

func (a *DuoCallApi) UpdateChatWechatPreference(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var body struct {
		Enabled bool `json:"enabled"`
	}
	if c.ShouldBindJSON(&body) != nil {
		response.FailWithMessage("微信消息设置格式不正确", c)
		return
	}
	partnerSlot := duoPartnerSlot(claims.Slot)
	mode := model.DuoPushModeDisabled
	if body.Enabled {
		mode = model.DuoPushModeNotificationOnly
	}
	var recipient model.DuoWechatRecipient
	result := global.GVA_DB.Where("slot = ?", partnerSlot).First(&recipient)
	if result.Error != nil && !errors.Is(result.Error, gorm.ErrRecordNotFound) {
		response.FailWithMessage("读取微信消息设置失败", c)
		return
	}
	if errors.Is(result.Error, gorm.ErrRecordNotFound) {
		recipient = model.DuoWechatRecipient{Slot: partnerSlot, ChatMode: mode}
		if err := global.GVA_DB.Create(&recipient).Error; err != nil {
			response.FailWithMessage("保存微信消息设置失败", c)
			return
		}
	} else {
		updates := map[string]any{"chat_mode": mode}
		if body.Enabled && recipient.EncryptedOpenID != "" {
			updates["enabled"] = true
			recipient.Enabled = true
		}
		if err := global.GVA_DB.Model(&recipient).Updates(updates).Error; err != nil {
			response.FailWithMessage("保存微信消息设置失败", c)
			return
		}
		recipient.ChatMode = mode
	}
	response.OkWithData(gin.H{
		"enabled":       duoChatWechatEnabled(recipient),
		"partnerOnline": duoSocketHub.online(partnerSlot),
	}, c)
}
func (a *DuoCallApi) Send(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var item model.DuoCallMessage
	if c.ShouldBindJSON(&item) != nil || strings.TrimSpace(item.Content) == "" || len([]rune(strings.TrimSpace(item.Content))) > 2000 {
		response.FailWithMessage("消息不能为空", c)
		return
	}
	item.ID = 0
	item.SenderSlot = claims.Slot
	item.Kind = "text"
	item.Content = strings.TrimSpace(item.Content)
	err := global.GVA_DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&item).Error; err != nil {
			return err
		}
		partnerSlot := duoPartnerSlot(claims.Slot)
		if duoSocketHub.online(partnerSlot) {
			return nil
		}
		delay := time.Duration(global.GVA_CONFIG.DuoRitual.ChatAggregationSeconds) * time.Second
		if delay <= 0 {
			delay = 8 * time.Second
		}
		_, err := duoPushService.Enqueue(tx, serviceSystem.DuoPushRequest{
			EventType: "chat-message", SourceType: "chat-message", SourceID: item.ID,
			RecipientSlot: partnerSlot, Title: "爱情小屋有新消息",
			FullContent: item.Content, GenericContent: "对方给你发来了一条新消息。",
			LinkRef:        fmt.Sprintf("chat:%d", item.ID),
			AggregationKey: fmt.Sprintf("chat:%d:%d", partnerSlot, claims.Slot),
		}, delay)
		return err
	})
	if err != nil {
		response.FailWithMessage("发送失败", c)
		return
	}
	local := time.Now().In(time.FixedZone("CST", 8*60*60))
	recordDuoGrowth(duoGrowthItem(
		"chat", fmt.Sprintf("%s:%d", local.Format("2006-01-02"), claims.Slot),
		item.ID, claims.Slot, 3, "今天也说了说话",
		"忙碌的日子里，仍然把一点时间留给了对方。", "", item.CreatedAt,
	))
	response.OkWithData(item, c)
}
func (a *DuoCallApi) Read(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	now := time.Now()
	global.GVA_DB.Model(&model.DuoCallMessage{}).Where("sender_slot <> ? AND read_at IS NULL", claims.Slot).Update("read_at", now)
	response.OkWithMessage("已读", c)
}
func (a *DuoCallApi) Unread(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var count int64
	global.GVA_DB.Model(&model.DuoCallMessage{}).Where("sender_slot <> ? AND read_at IS NULL", claims.Slot).Count(&count)
	response.OkWithData(gin.H{"count": count}, c)
}

func (a *DuoCallApi) SetStatus(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var body struct {
		StatusID uint `json:"statusId"`
	}
	if c.ShouldBindJSON(&body) != nil || body.StatusID == 0 {
		response.FailWithMessage("请选择状态", c)
		return
	}
	var status model.DuoCallStatus
	if global.GVA_DB.First(&status, "id = ? AND enabled = ?", body.StatusID, true).Error != nil {
		response.FailWithMessage("状态不可用", c)
		return
	}
	global.GVA_DB.Model(&model.DuoCallIdentity{}).Where("slot = ?", claims.Slot).Update("status_id", status.ID)
	if view, err := duoIdentityViewForSlot(claims.Slot); err == nil {
		duoBroadcastEvent("profile", view)
	}
	response.OkWithData(status, c)
}

func (a *DuoCallApi) UploadImage(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	file, err := c.FormFile("file")
	if err != nil || file.Size == 0 || file.Size > 10*1024*1024 {
		response.FailWithMessage("图片需小于 10MB", c)
		return
	}
	if !strings.HasPrefix(file.Header.Get("Content-Type"), "image/") {
		response.FailWithMessage("仅支持图片", c)
		return
	}
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true}
	if !allowed[ext] {
		response.FailWithMessage("图片格式不支持", c)
		return
	}
	dir := filepath.Join(duoStoreRoot(), "duo-call")
	if err = os.MkdirAll(dir, 0755); err != nil {
		response.FailWithMessage("创建存储目录失败", c)
		return
	}
	name := uuid.NewString() + ext
	if err = c.SaveUploadedFile(file, filepath.Join(dir, name)); err != nil {
		response.FailWithMessage("图片保存失败", c)
		return
	}
	item := model.DuoCallMessage{SenderSlot: claims.Slot, Kind: "image", ImageURL: "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/" + name}
	err = global.GVA_DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&item).Error; err != nil {
			return err
		}
		partnerSlot := uint(1)
		if claims.Slot == 1 {
			partnerSlot = 2
		}
		delay := time.Duration(global.GVA_CONFIG.DuoRitual.ChatAggregationSeconds) * time.Second
		if delay <= 0 {
			delay = 8 * time.Second
		}
		_, err := duoPushService.Enqueue(tx, serviceSystem.DuoPushRequest{
			EventType: "chat-message", SourceType: "chat-message", SourceID: item.ID,
			RecipientSlot: partnerSlot, Title: "爱情小屋有新图片",
			FullContent: "对方给你发来了一张图片。", GenericContent: "对方给你发来了一张图片。",
			LinkRef:        fmt.Sprintf("chat:%d", item.ID),
			AggregationKey: fmt.Sprintf("chat:%d:%d", partnerSlot, claims.Slot),
		}, delay)
		return err
	})
	if err != nil {
		response.FailWithMessage("创建消息失败", c)
		return
	}
	local := time.Now().In(time.FixedZone("CST", 8*60*60))
	recordDuoGrowth(duoGrowthItem(
		"chat", fmt.Sprintf("%s:%d", local.Format("2006-01-02"), claims.Slot),
		item.ID, claims.Slot, 3, "今天也说了说话",
		"分享一张图片，也是在说“这个瞬间想给你看”。", "", item.CreatedAt,
	))
	item.ImageURL = duoMediaURL(item.ImageURL)
	response.OkWithData(item, c)
}

func (a *DuoCallApi) Albums(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("pageSize", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 20 {
		pageSize = 20
	}
	var total int64
	var items []model.DuoCallAlbum
	global.GVA_DB.Model(&model.DuoCallAlbum{}).Count(&total)
	global.GVA_DB.Order("uploaded_at desc, id desc").Offset((page - 1) * pageSize).Limit(pageSize).Find(&items)
	for i := range items {
		items[i].ImageURL = duoMediaURL(items[i].ImageURL)
	}
	response.OkWithData(gin.H{"items": items, "total": total, "page": page, "pageSize": pageSize}, c)
}

func (a *DuoCallApi) UploadAlbum(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	file, err := c.FormFile("file")
	if err != nil || file.Size == 0 || file.Size > 10*1024*1024 {
		response.FailWithMessage("图片需小于 10MB", c)
		return
	}
	if !strings.HasPrefix(file.Header.Get("Content-Type"), "image/") {
		response.FailWithMessage("仅支持图片", c)
		return
	}
	ext := strings.ToLower(filepath.Ext(file.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".gif": true, ".webp": true}
	if !allowed[ext] {
		response.FailWithMessage("图片格式不支持", c)
		return
	}
	dir := filepath.Join(duoStoreRoot(), "duo-call", "album")
	if err = os.MkdirAll(dir, 0755); err != nil {
		response.FailWithMessage("创建存储目录失败", c)
		return
	}
	name := uuid.NewString() + ext
	if err = c.SaveUploadedFile(file, filepath.Join(dir, name)); err != nil {
		response.FailWithMessage("图片保存失败", c)
		return
	}
	item := model.DuoCallAlbum{UploaderSlot: claims.Slot, ImageURL: "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/album/" + name, UploadedAt: time.Now()}
	if err = global.GVA_DB.Create(&item).Error; err != nil {
		_ = os.Remove(filepath.Join(dir, name))
		response.FailWithMessage("创建相册记录失败", c)
		return
	}
	recordDuoGrowth(duoGrowthItem(
		"album", strconv.FormatUint(uint64(item.ID), 10), item.ID, claims.Slot, 12,
		"收藏了一张照片", "一张共同的小瞬间被放进了相册。", item.ImageURL, item.UploadedAt,
	))
	partnerSlot := uint(1)
	if claims.Slot == 1 {
		partnerSlot = 2
	}
	_, _ = duoPushService.Enqueue(global.GVA_DB, serviceSystem.DuoPushRequest{
		EventType: "tree-growth", SourceType: "album", SourceID: item.ID,
		RecipientSlot: partnerSlot, Title: "我们的树开出了一朵花",
		FullContent:    "TA 收藏了一张新照片，你们的树又长大了一点。",
		GenericContent: "你们的树因为一个新瞬间长大了。", LinkRef: fmt.Sprintf("tree:event:%d", item.ID),
	}, 0)
	item.ImageURL = duoMediaURL(item.ImageURL)
	response.OkWithData(item, c)
}

func (a *DuoCallApi) DeleteOwnAlbum(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	var item model.DuoCallAlbum
	if global.GVA_DB.First(&item, uint(id)).Error != nil {
		response.FailWithMessage("图片不存在", c)
		return
	}
	global.GVA_DB.Delete(&item)
	global.GVA_DB.Model(&model.DuoGrowthEvent{}).
		Where("source_key = ?", fmt.Sprintf("album:%d", item.ID)).
		Update("image_url", "")
	removeDuoAlbumFile(item.ImageURL)
	response.OkWithMessage("已删除图片", c)
}

func (a *DuoCallApi) Anniversaries(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	var items []model.DuoCallAnniversary
	global.GVA_DB.Where("enabled = ?", true).Order("sort asc, date asc").Find(&items)
	response.OkWithData(items, c)
}

func (a *DuoCallApi) Notes(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	if c.Query("latestByMember") == "true" {
		var candidates []model.DuoCallNote
		global.GVA_DB.Order("id desc").Limit(100).Find(&candidates)
		response.OkWithData(latestDuoNotesByMember(candidates), c)
		return
	}
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "1"))
	if limit < 1 || limit > 50 {
		limit = 1
	}
	var items []model.DuoCallNote
	global.GVA_DB.Order("id desc").Limit(limit).Find(&items)
	response.OkWithData(items, c)
}

func latestDuoNotesByMember(candidates []model.DuoCallNote) []model.DuoCallNote {
	items := make([]model.DuoCallNote, 0, 2)
	seen := map[uint]bool{}
	for _, item := range candidates {
		if seen[item.SenderSlot] {
			continue
		}
		seen[item.SenderSlot] = true
		items = append(items, item)
		if len(items) == 2 {
			break
		}
	}
	return items
}

func (a *DuoCallApi) SendNote(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var body struct {
		Content string `json:"content"`
	}
	if c.ShouldBindJSON(&body) != nil || strings.TrimSpace(body.Content) == "" || len([]rune(body.Content)) > 500 {
		response.FailWithMessage("留言需要在 1 到 500 字内", c)
		return
	}
	item := model.DuoCallNote{SenderSlot: claims.Slot, Content: strings.TrimSpace(body.Content)}
	if global.GVA_DB.Create(&item).Error != nil {
		response.FailWithMessage("保存留言失败", c)
		return
	}
	recordDuoGrowth(duoGrowthItem(
		"note", strconv.FormatUint(uint64(item.ID), 10), item.ID, claims.Slot, 4,
		"留下了一句心里话", item.Content, "", item.CreatedAt,
	))
	partnerSlot := uint(1)
	if claims.Slot == 1 {
		partnerSlot = 2
	}
	_, _ = duoPushService.Enqueue(global.GVA_DB, serviceSystem.DuoPushRequest{
		EventType: "tree-growth", SourceType: "note", SourceID: item.ID,
		RecipientSlot: partnerSlot, Title: "树下多了一句心里话",
		FullContent: item.Content, GenericContent: "TA 在你们的树下留了一句话。",
		LinkRef: fmt.Sprintf("tree:event:%d", item.ID),
	}, 0)
	duoBroadcastEvent("note", item)
	response.OkWithData(item, c)
}

func (a *DuoCallApi) SendMissYou(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	partnerSlot := duoPartnerSlot(claims.Slot)
	item := model.DuoMissYou{
		SenderSlot: claims.Slot, RecipientSlot: partnerSlot,
		Message: "我想你了",
	}
	var queued bool
	err := global.GVA_DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(&item).Error; err != nil {
			return err
		}
		var err error
		queued, err = duoPushService.Enqueue(tx, serviceSystem.DuoPushRequest{
			EventType: "miss-you", SourceType: "miss-you", SourceID: item.ID,
			RecipientSlot: partnerSlot, Title: "有人在偷偷想你",
			FullContent: item.Message, GenericContent: "有人在爱情小屋里偷偷想你。",
			LinkRef: fmt.Sprintf("miss-you:%d", item.ID),
		}, 0)
		return err
	})
	if err != nil {
		response.FailWithMessage("想念暂时没有送出去，请稍后再试", c)
		return
	}
	duoBroadcastEventToSlot("miss-you", partnerSlot, item)
	response.OkWithData(gin.H{
		"ID": item.ID, "message": item.Message, "wechatQueued": queued,
		"partnerOnline": duoSocketHub.online(partnerSlot),
	}, c)
}

func (a *DuoCallApi) PendingMissYou(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var items []model.DuoMissYou
	if err := global.GVA_DB.Where("recipient_slot = ? AND acknowledged_at IS NULL", claims.Slot).
		Order("created_at desc, id desc").Limit(1).Find(&items).Error; err != nil {
		response.FailWithMessage("读取想念失败", c)
		return
	}
	response.OkWithData(items, c)
}

func (a *DuoCallApi) AcknowledgeMissYou(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("想念编号不正确", c)
		return
	}
	now := time.Now()
	result := global.GVA_DB.Model(&model.DuoMissYou{}).
		Where("id = ? AND recipient_slot = ? AND acknowledged_at IS NULL", id, claims.Slot).
		Update("acknowledged_at", now)
	if result.Error != nil {
		response.FailWithMessage("确认想念失败", c)
		return
	}
	response.OkWithMessage("已收到这份想念", c)
}

func removeDuoAlbumFile(url string) {
	prefix := "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/album/"
	if !strings.HasPrefix(url, prefix) {
		return
	}
	_ = os.Remove(filepath.Join(duoStoreRoot(), "duo-call", "album", filepath.Base(url)))
}

func (a *DuoCallApi) CheckAppUpdate(c *gin.Context) {
	platform := strings.ToLower(strings.TrimSpace(c.Query("platform")))
	currentVersion, err := duoNormalizedVersion(c.Query("version"))
	if !duoReleasePlatforms[platform] || err != nil {
		response.FailWithMessage("客户端版本信息不正确", c)
		return
	}
	var releases []model.DuoAppRelease
	if err := global.GVA_DB.Where("platform = ? AND published = ?", platform, true).
		Find(&releases).Error; err != nil {
		response.FailWithMessage("暂时无法检查更新", c)
		return
	}
	var latest *model.DuoAppRelease
	for index := range releases {
		if latest == nil {
			latest = &releases[index]
			continue
		}
		comparison, compareErr := duoCompareVersions(releases[index].Version, latest.Version)
		if compareErr == nil && comparison > 0 {
			latest = &releases[index]
		}
	}
	if latest == nil {
		response.OkWithData(gin.H{"updateAvailable": false}, c)
		return
	}
	comparison, err := duoCompareVersions(latest.Version, currentVersion)
	if err != nil || comparison <= 0 {
		response.OkWithData(gin.H{"updateAvailable": false}, c)
		return
	}
	response.OkWithData(gin.H{
		"updateAvailable": true,
		"release":         duoReleaseView(*latest),
	}, c)
}

func duoReleaseDownloadURL(value string) (string, error) {
	value = strings.TrimSpace(value)
	if value == "" {
		return "", errors.New("请填写下载地址")
	}
	if strings.HasPrefix(value, "/") {
		if !strings.HasPrefix(value, "/uploads/") {
			return "", errors.New("本地下载地址必须位于 /uploads/ 路径下")
		}
		return duoReleasePublicURL(value), nil
	}
	parsed, err := url.ParseRequestURI(value)
	if err != nil || parsed.Host == "" || (parsed.Scheme != "https" && parsed.Scheme != "http") {
		return "", errors.New("下载地址必须是完整的 HTTP 或 HTTPS 地址")
	}
	return value, nil
}

func (a *DuoCallApi) UploadAppReleaseFile(c *gin.Context) {
	platform := strings.ToLower(strings.TrimSpace(c.PostForm("platform")))
	if !duoReleasePlatforms[platform] {
		response.FailWithMessage("请选择正确的发布平台", c)
		return
	}
	file, err := c.FormFile("file")
	if err != nil || file == nil {
		response.FailWithMessage("请选择安装包文件", c)
		return
	}
	if file.Size <= 0 || file.Size > duoReleaseMaxFileBytes {
		response.FailWithMessage("安装包必须大于 0 且不超过 512MB", c)
		return
	}
	if filepath.Base(file.Filename) != file.Filename {
		response.FailWithMessage("文件名不合法", c)
		return
	}
	extension := strings.ToLower(filepath.Ext(file.Filename))
	if !duoReleaseExtensionAllowed(platform, extension) {
		response.FailWithMessage("该平台不支持此安装包格式", c)
		return
	}

	var fileURL string
	if strings.EqualFold(global.GVA_CONFIG.System.OssType, "local") || strings.TrimSpace(global.GVA_CONFIG.System.OssType) == "" {
		dir := filepath.Join(duoStoreRoot(), "duo-call", "releases")
		if err = os.MkdirAll(dir, 0755); err != nil {
			response.FailWithMessage("创建安装包目录失败", c)
			return
		}
		name := uuid.NewString() + extension
		if err = c.SaveUploadedFile(file, filepath.Join(dir, name)); err != nil {
			response.FailWithMessage("保存安装包失败", c)
			return
		}
		publicStorePath := strings.TrimSpace(global.GVA_CONFIG.Local.Path)
		if publicStorePath == "" {
			publicStorePath = global.GVA_CONFIG.Local.StorePath
		}
		fileURL = "/" + strings.Trim(publicStorePath, "/") + "/duo-call/releases/" + name
	} else {
		fileURL, _, err = upload.NewOss().UploadFile(file)
		if err != nil {
			response.FailWithMessage("上传安装包失败", c)
			return
		}
	}

	response.OkWithData(gin.H{
		"url":      duoReleasePublicURL(fileURL),
		"name":     file.Filename,
		"size":     file.Size,
		"platform": platform,
	}, c)
}

func (a *DuoCallApi) SaveAppRelease(c *gin.Context) {
	var body struct {
		ID           uint   `json:"ID"`
		Platform     string `json:"platform"`
		Version      string `json:"version"`
		DownloadURL  string `json:"downloadUrl"`
		ReleaseNotes string `json:"releaseNotes"`
		ForceUpdate  bool   `json:"forceUpdate"`
		Published    bool   `json:"published"`
	}
	if c.ShouldBindJSON(&body) != nil {
		response.FailWithMessage("发版数据格式不正确", c)
		return
	}
	body.Platform = strings.ToLower(strings.TrimSpace(body.Platform))
	version, err := duoNormalizedVersion(body.Version)
	if !duoReleasePlatforms[body.Platform] || err != nil {
		response.FailWithMessage("请选择平台并填写语义化版本号，例如 1.2.0", c)
		return
	}
	if len([]rune(body.ReleaseNotes)) > 5000 {
		response.FailWithMessage("更新说明不能超过 5000 个字", c)
		return
	}
	downloadURL := strings.TrimSpace(body.DownloadURL)
	if body.Published {
		if downloadURL, err = duoReleaseDownloadURL(downloadURL); err != nil {
			response.FailWithMessage(err.Error(), c)
			return
		}
	}
	item := model.DuoAppRelease{}
	if body.ID != 0 {
		if err := global.GVA_DB.First(&item, body.ID).Error; err != nil {
			response.FailWithMessage("发布记录不存在", c)
			return
		}
	}
	item.Platform = body.Platform
	item.Version = version
	item.DownloadURL = downloadURL
	item.ReleaseNotes = strings.TrimSpace(body.ReleaseNotes)
	item.ForceUpdate = body.ForceUpdate
	item.Published = body.Published
	if body.Published && item.PublishedAt == nil {
		now := time.Now()
		item.PublishedAt = &now
	}
	if !body.Published {
		item.PublishedAt = nil
	}
	if err := global.GVA_DB.Save(&item).Error; err != nil {
		response.FailWithMessage("保存发布记录失败：同一平台不能重复使用版本号", c)
		return
	}
	response.OkWithData(duoReleaseView(item), c)
}

func (a *DuoCallApi) DeleteAppRelease(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	result := global.GVA_DB.Delete(&model.DuoAppRelease{}, uint(id))
	if result.Error != nil || result.RowsAffected == 0 {
		response.FailWithMessage("发布记录不存在", c)
		return
	}
	response.OkWithMessage("已删除发布记录", c)
}

func (a *DuoCallApi) AdminList(c *gin.Context) {
	// The application has exactly two fixed members. Create both editable,
	// disabled slots on first visit instead of requiring an "add" action.
	for slot := uint(1); slot <= 2; slot++ {
		var count int64
		global.GVA_DB.Model(&model.DuoCallIdentity{}).Where("slot = ?", slot).Count(&count)
		if count == 0 {
			global.GVA_DB.Create(&model.DuoCallIdentity{Slot: slot, DisplayName: "成员 " + strconv.Itoa(int(slot)), Enabled: false, KeyVersion: 1})
		}
	}
	var identities []model.DuoCallIdentity
	var statuses []model.DuoCallStatus
	var messages []model.DuoCallMessage
	var albums []model.DuoCallAlbum
	var anniversaries []model.DuoCallAnniversary
	var releases []model.DuoAppRelease
	global.GVA_DB.Order("slot").Find(&identities)
	global.GVA_DB.Order("sort").Find(&statuses)
	global.GVA_DB.Order("id desc").Limit(500).Find(&messages)
	global.GVA_DB.Order("uploaded_at desc, id desc").Limit(500).Find(&albums)
	for i := range messages {
		messages[i].ImageURL = duoMediaURL(messages[i].ImageURL)
	}
	for i := range albums {
		albums[i].ImageURL = duoMediaURL(albums[i].ImageURL)
	}
	global.GVA_DB.Order("sort asc, date asc").Find(&anniversaries)
	global.GVA_DB.Order("published desc, published_at desc, id desc").Find(&releases)
	keys := make([]gin.H, 0, len(identities))
	for _, identity := range identities {
		key := ""
		if identity.EncryptedKey != "" {
			key, _ = duoCallService.DecryptKey(identity.EncryptedKey)
		}
		keys = append(keys, gin.H{"ID": identity.ID, "slot": identity.Slot, "displayName": identity.DisplayName, "avatarUrl": duoMediaURL(identity.AvatarURL), "key": key, "enabled": identity.Enabled, "statusId": identity.StatusID})
	}
	releaseViews := make([]duoAppReleaseView, 0, len(releases))
	for _, item := range releases {
		releaseViews = append(releaseViews, duoReleaseView(item))
	}
	response.OkWithData(gin.H{"identities": keys, "statuses": statuses, "messages": messages, "albums": albums, "anniversaries": anniversaries, "releases": releaseViews}, c)
}
func (a *DuoCallApi) SaveIdentity(c *gin.Context) {
	var body struct {
		ID          uint   `json:"ID"`
		Slot        uint   `json:"slot"`
		DisplayName string `json:"displayName"`
		Key         string `json:"key"`
		Enabled     bool   `json:"enabled"`
		StatusID    *uint  `json:"statusId"`
	}
	if c.ShouldBindJSON(&body) != nil || (body.Slot != 1 && body.Slot != 2) || strings.TrimSpace(body.Key) == "" {
		response.FailWithMessage("请填写两个槽位中的名称和秘钥", c)
		return
	}
	var item model.DuoCallIdentity
	result := global.GVA_DB.Where("slot = ?", body.Slot).First(&item)
	encrypted, err := duoCallService.EncryptKey(body.Key)
	if err != nil {
		response.FailWithMessage("秘钥加密失败", c)
		return
	}
	if result.Error != nil {
		item = model.DuoCallIdentity{Slot: body.Slot, DisplayName: body.DisplayName, EncryptedKey: encrypted, Enabled: body.Enabled, StatusID: body.StatusID, KeyVersion: 1}
	} else {
		changed := ""
		if item.EncryptedKey != "" {
			changed, _ = duoCallService.DecryptKey(item.EncryptedKey)
		}
		if changed != body.Key {
			item.KeyVersion++
		}
		item.DisplayName = body.DisplayName
		item.EncryptedKey = encrypted
		item.Enabled = body.Enabled
		item.StatusID = body.StatusID
	}
	if err = global.GVA_DB.Save(&item).Error; err != nil {
		response.FailWithMessage("保存失败", c)
		return
	}
	response.OkWithMessage("已保存，修改秘钥会使旧会话失效", c)
}
func (a *DuoCallApi) SaveStatus(c *gin.Context) {
	var item model.DuoCallStatus
	if c.ShouldBindJSON(&item) != nil || strings.TrimSpace(item.Label) == "" {
		response.FailWithMessage("请填写状态名称", c)
		return
	}
	if item.ID == 0 {
		global.GVA_DB.Create(&item)
	} else {
		global.GVA_DB.Save(&item)
	}
	response.OkWithData(item, c)
}
func (a *DuoCallApi) DeleteStatus(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	global.GVA_DB.Delete(&model.DuoCallStatus{}, uint(id))
	response.OkWithMessage("已删除", c)
}

func (a *DuoCallApi) SaveAlbum(c *gin.Context) {
	var body struct {
		ID           uint      `json:"ID"`
		UploaderSlot uint      `json:"uploaderSlot"`
		UploadedAt   time.Time `json:"uploadedAt"`
	}
	if c.ShouldBindJSON(&body) != nil || body.ID == 0 || (body.UploaderSlot != 1 && body.UploaderSlot != 2) || body.UploadedAt.IsZero() {
		response.FailWithMessage("请填写上传用户和上传日期", c)
		return
	}
	var item model.DuoCallAlbum
	if global.GVA_DB.First(&item, body.ID).Error != nil {
		response.FailWithMessage("图片不存在", c)
		return
	}
	item.UploaderSlot = body.UploaderSlot
	item.UploadedAt = body.UploadedAt
	if global.GVA_DB.Save(&item).Error != nil {
		response.FailWithMessage("保存失败", c)
		return
	}
	response.OkWithData(item, c)
}

func (a *DuoCallApi) DeleteAlbum(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	var item model.DuoCallAlbum
	if global.GVA_DB.First(&item, uint(id)).Error != nil {
		response.FailWithMessage("图片不存在", c)
		return
	}
	global.GVA_DB.Delete(&item)
	removeDuoAlbumFile(item.ImageURL)
	response.OkWithMessage("已删除图片", c)
}

func (a *DuoCallApi) SaveAnniversary(c *gin.Context) {
	var item model.DuoCallAnniversary
	if c.ShouldBindJSON(&item) != nil || strings.TrimSpace(item.Title) == "" || item.Date.IsZero() {
		response.FailWithMessage("请填写纪念日名称和日期", c)
		return
	}
	if item.ID == 0 {
		global.GVA_DB.Create(&item)
	} else {
		global.GVA_DB.Save(&item)
	}
	response.OkWithData(item, c)
}

func (a *DuoCallApi) DeleteAnniversary(c *gin.Context) {
	id, err := strconv.ParseUint(c.Query("ID"), 10, 64)
	if err != nil || id == 0 {
		response.FailWithMessage("参数错误", c)
		return
	}
	global.GVA_DB.Delete(&model.DuoCallAnniversary{}, uint(id))
	response.OkWithMessage("已删除", c)
}
