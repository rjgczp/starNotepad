package system

import (
	"crypto/subtle"
	"errors"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	model "github.com/flipped-aurora/gin-vue-admin/server/model/system"
	"github.com/gin-gonic/gin"
	jwt "github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type DuoCallApi struct{}
type duoClaims struct {
	Slot       uint `json:"slot"`
	KeyVersion uint `json:"kv"`
	jwt.RegisteredClaims
}

// duoMediaURL routes uploaded files through the same /api origin as the JSON
// endpoints. This works for the standalone 3002 app, the admin app and nginx.
func duoMediaURL(value string) string {
	if value == "" || strings.HasPrefix(value, "http://") || strings.HasPrefix(value, "https://") || strings.HasPrefix(value, "//") {
		return value
	}
	prefix := "/" + strings.Trim(global.GVA_CONFIG.System.RouterPrefix, "/")
	if prefix == "/" || strings.HasPrefix(value, prefix+"/") {
		return value
	}
	return prefix + "/" + strings.TrimLeft(value, "/")
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

func (a *DuoCallApi) Login(c *gin.Context) {
	var body struct {
		Key string `json:"key"`
	}
	if c.ShouldBindJSON(&body) != nil || strings.TrimSpace(body.Key) == "" {
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
			response.OkWithData(gin.H{"token": token, "slot": item.Slot, "displayName": item.DisplayName}, c)
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
	data := gin.H{"me": claims.Slot, "identities": identities, "statuses": statuses}
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
func (a *DuoCallApi) History(c *gin.Context) {
	if _, ok := duoAuth(c); !ok {
		return
	}
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	if limit < 1 || limit > 100 {
		limit = 50
	}
	var messages []model.DuoCallMessage
	global.GVA_DB.Order("id desc").Limit(limit).Find(&messages)
	for i := range messages {
		messages[i].ImageURL = duoMediaURL(messages[i].ImageURL)
	}
	response.OkWithData(messages, c)
}
func (a *DuoCallApi) Send(c *gin.Context) {
	claims, ok := duoAuth(c)
	if !ok {
		return
	}
	var item model.DuoCallMessage
	if c.ShouldBindJSON(&item) != nil || strings.TrimSpace(item.Content) == "" {
		response.FailWithMessage("消息不能为空", c)
		return
	}
	item.ID = 0
	item.SenderSlot = claims.Slot
	item.Kind = "text"
	if global.GVA_DB.Create(&item).Error != nil {
		response.FailWithMessage("发送失败", c)
		return
	}
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
	dir := filepath.Join(global.GVA_CONFIG.Local.StorePath, "duo-call")
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
	if err = global.GVA_DB.Create(&item).Error; err != nil {
		response.FailWithMessage("创建消息失败", c)
		return
	}
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
	dir := filepath.Join(global.GVA_CONFIG.Local.StorePath, "duo-call", "album")
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
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "1"))
	if limit < 1 || limit > 50 {
		limit = 1
	}
	var items []model.DuoCallNote
	global.GVA_DB.Order("id desc").Limit(limit).Find(&items)
	response.OkWithData(items, c)
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
	response.OkWithData(item, c)
}

func removeDuoAlbumFile(url string) {
	prefix := "/" + strings.Trim(global.GVA_CONFIG.Local.StorePath, "/") + "/duo-call/album/"
	if !strings.HasPrefix(url, prefix) {
		return
	}
	_ = os.Remove(filepath.Join(global.GVA_CONFIG.Local.StorePath, "duo-call", "album", filepath.Base(url)))
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
	keys := make([]gin.H, 0, len(identities))
	for _, identity := range identities {
		key := ""
		if identity.EncryptedKey != "" {
			key, _ = duoCallService.DecryptKey(identity.EncryptedKey)
		}
		keys = append(keys, gin.H{"ID": identity.ID, "slot": identity.Slot, "displayName": identity.DisplayName, "key": key, "enabled": identity.Enabled, "statusId": identity.StatusID})
	}
	response.OkWithData(gin.H{"identities": keys, "statuses": statuses, "messages": messages, "albums": albums, "anniversaries": anniversaries}, c)
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
