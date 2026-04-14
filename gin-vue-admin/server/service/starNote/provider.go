package starNote

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	starNoteReq "github.com/flipped-aurora/gin-vue-admin/server/model/starNote/request"
	requestUtils "github.com/flipped-aurora/gin-vue-admin/server/utils/request"
	"gorm.io/gorm"
)

type ProviderService struct{}

const providerAPIKeyEncryptPrefix = "enc::"

func providerCryptoKey() []byte {
	signingKey := global.GVA_CONFIG.JWT.SigningKey
	if signingKey == "" {
		signingKey = "gva-provider-default-key"
	}
	sum := sha256.Sum256([]byte(signingKey))
	return sum[:]
}

func encryptProviderAPIKey(raw string) (string, error) {
	if raw == "" {
		return "", nil
	}
	if strings.HasPrefix(raw, providerAPIKeyEncryptPrefix) {
		if _, err := decryptProviderAPIKey(raw); err == nil {
			return raw, nil
		}
	}
	block, err := aes.NewCipher(providerCryptoKey())
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}
	ciphertext := gcm.Seal(nil, nonce, []byte(raw), nil)
	payload := append(nonce, ciphertext...)
	return providerAPIKeyEncryptPrefix + base64.StdEncoding.EncodeToString(payload), nil
}

func decryptProviderAPIKey(stored string) (string, error) {
	if stored == "" {
		return "", nil
	}
	if !strings.HasPrefix(stored, providerAPIKeyEncryptPrefix) {
		return stored, nil
	}
	encoded := strings.TrimPrefix(stored, providerAPIKeyEncryptPrefix)
	payload, err := base64.StdEncoding.DecodeString(encoded)
	if err != nil {
		return "", err
	}
	block, err := aes.NewCipher(providerCryptoKey())
	if err != nil {
		return "", err
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", err
	}
	nonceSize := gcm.NonceSize()
	if len(payload) < nonceSize {
		return "", errors.New("invalid encrypted api key payload")
	}
	nonce := payload[:nonceSize]
	ciphertext := payload[nonceSize:]
	plain, err := gcm.Open(nil, nonce, ciphertext, nil)
	if err != nil {
		return "", err
	}
	return string(plain), nil
}

func decryptProviderEntity(provider *starNote.Provider) {
	if provider == nil || provider.ApiKey == nil {
		return
	}
	if plain, err := decryptProviderAPIKey(*provider.ApiKey); err == nil {
		provider.ApiKey = &plain
	}
}

func deactivateOtherProviders(tx *gorm.DB, currentID uint) error {
	query := tx.Model(&starNote.Provider{}).Where("is_active = ?", true)
	if currentID != 0 {
		query = query.Where("id <> ?", currentID)
	}
	return query.Update("is_active", false).Error
}

// CreateProvider 创建AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) CreateProvider(ctx context.Context, aiProvider *starNote.Provider) (err error) {
	return global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if aiProvider.ApiKey != nil {
			encrypted, encErr := encryptProviderAPIKey(*aiProvider.ApiKey)
			if encErr != nil {
				return encErr
			}
			aiProvider.ApiKey = &encrypted
		}
		if aiProvider.IsActive != nil && *aiProvider.IsActive {
			if err = deactivateOtherProviders(tx, 0); err != nil {
				return err
			}
		}
		return tx.Create(aiProvider).Error
	})
}

// DeleteProvider 删除AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) DeleteProvider(ctx context.Context, ID string) (err error) {
	err = global.GVA_DB.WithContext(ctx).Delete(&starNote.Provider{}, "id = ?", ID).Error
	return err
}

// DeleteProviderByIds 批量删除AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) DeleteProviderByIds(ctx context.Context, IDs []string) (err error) {
	err = global.GVA_DB.WithContext(ctx).Delete(&[]starNote.Provider{}, "id in ?", IDs).Error
	return err
}

// UpdateProvider 更新AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) UpdateProvider(ctx context.Context, aiProvider starNote.Provider) (err error) {
	return global.GVA_DB.WithContext(ctx).Transaction(func(tx *gorm.DB) error {
		if aiProvider.ApiKey != nil {
			encrypted, encErr := encryptProviderAPIKey(*aiProvider.ApiKey)
			if encErr != nil {
				return encErr
			}
			aiProvider.ApiKey = &encrypted
		}
		if aiProvider.IsActive != nil && *aiProvider.IsActive {
			if err = deactivateOtherProviders(tx, aiProvider.ID); err != nil {
				return err
			}
		}
		return tx.Model(&starNote.Provider{}).Where("id = ?", aiProvider.ID).Updates(&aiProvider).Error
	})
}

// GetProvider 根据ID获取AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) GetProvider(ctx context.Context, ID string) (aiProvider starNote.Provider, err error) {
	err = global.GVA_DB.WithContext(ctx).Where("id = ?", ID).First(&aiProvider).Error
	if err != nil {
		return
	}
	decryptProviderEntity(&aiProvider)
	return
}

// GetProviderInfoList 分页获取AI供应商记录
// Author [yourname](https://github.com/yourname)
func (aiProviderService *ProviderService) GetProviderInfoList(ctx context.Context, info starNoteReq.ProviderSearch) (list []starNote.Provider, total int64, err error) {
	limit := info.PageSize
	offset := info.PageSize * (info.Page - 1)
	// 创建db
	db := global.GVA_DB.WithContext(ctx).Model(&starNote.Provider{})
	var aiProviders []starNote.Provider
	// 如果有条件搜索 下方会自动创建搜索语句
	if len(info.CreatedAtRange) == 2 {
		db = db.Where("created_at BETWEEN ? AND ?", info.CreatedAtRange[0], info.CreatedAtRange[1])
	}

	err = db.Count(&total).Error
	if err != nil {
		return
	}

	if limit != 0 {
		db = db.Limit(limit).Offset(offset)
	}

	err = db.Find(&aiProviders).Error
	if err != nil {
		return nil, 0, err
	}
	for i := range aiProviders {
		decryptProviderEntity(&aiProviders[i])
	}
	return aiProviders, total, err
}

func (aiProviderService *ProviderService) GetProviderPublic(ctx context.Context) {
	// 此方法为获取数据源定义的数据
	// 请自行实现
}

type providerInvokeConfig struct {
	AuthType   string `json:"authType"`
	AuthHeader string `json:"authHeader"`
}

func parseProviderInvokeConfig(configRaw string) providerInvokeConfig {
	cfg := providerInvokeConfig{AuthType: "bearer", AuthHeader: "x-api-key"}
	if strings.TrimSpace(configRaw) == "" {
		return cfg
	}
	if err := json.Unmarshal([]byte(configRaw), &cfg); err != nil {
		return providerInvokeConfig{AuthType: "bearer", AuthHeader: "x-api-key"}
	}
	cfg.AuthType = strings.ToLower(strings.TrimSpace(cfg.AuthType))
	if cfg.AuthType != "header" {
		cfg.AuthType = "bearer"
	}
	if strings.TrimSpace(cfg.AuthHeader) == "" {
		cfg.AuthHeader = "x-api-key"
	}
	return cfg
}

func joinProviderURL(baseURL, path string) string {
	b := strings.TrimSpace(baseURL)
	p := strings.TrimSpace(path)
	b = strings.TrimRight(b, "/")
	if p == "" {
		return b
	}
	if strings.HasPrefix(p, "http://") || strings.HasPrefix(p, "https://") {
		return p
	}
	if !strings.HasPrefix(p, "/") {
		p = "/" + p
	}
	return b + p
}

func getActiveProvider(ctx context.Context) (starNote.Provider, error) {
	var provider starNote.Provider
	err := global.GVA_DB.WithContext(ctx).
		Where("is_active = ?", true).
		Order("id desc").
		First(&provider).Error
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return provider, errors.New("当前没有已启用的AI供应商")
		}
		return provider, err
	}
	return provider, nil
}

func getProviderModel(configRaw string) string {
	defaultModel := "gpt-4o-mini"
	if strings.TrimSpace(configRaw) == "" {
		return defaultModel
	}
	var cfg map[string]interface{}
	if err := json.Unmarshal([]byte(configRaw), &cfg); err != nil {
		return defaultModel
	}
	for _, key := range []string{"model", "modelName", "model_name"} {
		if v, ok := cfg[key].(string); ok && strings.TrimSpace(v) != "" {
			return strings.TrimSpace(v)
		}
	}
	return defaultModel
}

func (aiProviderService *ProviderService) InvokeActiveProvider(ctx context.Context, req starNoteReq.ProviderInvokeReq) (map[string]interface{}, error) {
	provider, err := getActiveProvider(ctx)
	if err != nil {
		return nil, err
	}

	decryptProviderEntity(&provider)
	if provider.BaseUrl == nil || strings.TrimSpace(*provider.BaseUrl) == "" {
		return nil, errors.New("已启用供应商缺少API地址")
	}

	method := strings.ToUpper(strings.TrimSpace(req.Method))
	if method == "" {
		method = http.MethodPost
	}

	headers := map[string]string{}
	for k, v := range req.Headers {
		headers[k] = v
	}

	apiKey := ""
	if provider.ApiKey != nil {
		apiKey = strings.TrimSpace(*provider.ApiKey)
	}
	authType := "bearer"
	authHeader := "x-api-key"
	if provider.ConfigJson != nil {
		cfg := parseProviderInvokeConfig(*provider.ConfigJson)
		authType = cfg.AuthType
		authHeader = cfg.AuthHeader
	}
	if apiKey != "" {
		if authType == "header" {
			if _, exists := headers[authHeader]; !exists {
				headers[authHeader] = apiKey
			}
		} else {
			if _, exists := headers["Authorization"]; !exists {
				headers["Authorization"] = "Bearer " + apiKey
			}
		}
	}

	targetURL := joinProviderURL(*provider.BaseUrl, req.Path)
	resp, err := requestUtils.HttpRequest(targetURL, method, headers, req.Params, req.Body)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	result := map[string]interface{}{
		"providerId":      provider.ID,
		"providerName":    provider.ProviderName,
		"authType":        authType,
		"statusCode":      resp.StatusCode,
		"responseHeaders": resp.Header,
		"raw":             string(body),
	}

	var parsed interface{}
	if len(body) > 0 && json.Unmarshal(body, &parsed) == nil {
		result["data"] = parsed
	}

	return result, nil
}

func parsePolishResult(raw string) map[string]string {
	result := map[string]string{
		"title":   "",
		"content": strings.TrimSpace(raw),
	}
	trimmed := strings.TrimSpace(raw)
	if trimmed == "" {
		return result
	}

	var obj map[string]interface{}
	if json.Unmarshal([]byte(trimmed), &obj) == nil {
		if v, ok := obj["title"].(string); ok {
			result["title"] = strings.TrimSpace(v)
		}
		if v, ok := obj["content"].(string); ok {
			result["content"] = strings.TrimSpace(v)
		}
		return result
	}

	lines := strings.Split(trimmed, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "标题:") || strings.HasPrefix(line, "标题：") {
			result["title"] = strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(line, "标题:"), "标题："))
		}
		if strings.HasPrefix(line, "内容:") || strings.HasPrefix(line, "内容：") {
			result["content"] = strings.TrimSpace(strings.TrimPrefix(strings.TrimPrefix(line, "内容:"), "内容："))
		}
	}
	return result
}

func extractOpenAIContent(data interface{}) string {
	m, ok := data.(map[string]interface{})
	if !ok {
		return ""
	}
	choices, ok := m["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return ""
	}
	choice0, ok := choices[0].(map[string]interface{})
	if !ok {
		return ""
	}
	message, ok := choice0["message"].(map[string]interface{})
	if !ok {
		return ""
	}
	content, _ := message["content"].(string)
	return content
}

func (aiProviderService *ProviderService) PolishUserInput(ctx context.Context, text string) (map[string]string, error) {
	activeProvider, err := getActiveProvider(ctx)
	if err != nil {
		return nil, err
	}
	model := ""
	if activeProvider.ProviderName != nil {
		model = strings.TrimSpace(*activeProvider.ProviderName)
	}
	if model == "" && activeProvider.ConfigJson != nil {
		model = getProviderModel(*activeProvider.ConfigJson)
	}
	if model == "" {
		model = "gpt-4o-mini"
	}

	prompt := "请将用户输入润色为适合记事本保存的内容。严格返回 JSON 对象，格式为 {\"title\":\"...\",\"content\":\"...\"}，不要输出其他解释。"
	invokeReq := starNoteReq.ProviderInvokeReq{
		Path:   "/chat/completions",
		Method: http.MethodPost,
		Body: map[string]interface{}{
			"model": model,
			"messages": []map[string]string{
				{"role": "system", "content": prompt},
				{"role": "user", "content": text},
			},
		},
	}

	result, err := aiProviderService.InvokeActiveProvider(ctx, invokeReq)
	if err != nil {
		return nil, err
	}

	if statusCode, ok := result["statusCode"].(int); ok && statusCode >= http.StatusBadRequest {
		if data, ok := result["data"].(map[string]interface{}); ok {
			if errObj, ok := data["error"].(map[string]interface{}); ok {
				if msg, ok := errObj["message"].(string); ok && strings.TrimSpace(msg) != "" {
					return nil, errors.New(msg)
				}
			}
		}
		if raw, ok := result["raw"].(string); ok && strings.TrimSpace(raw) != "" {
			return nil, errors.New(raw)
		}
		return nil, errors.New("AI服务调用失败")
	}

	if data, ok := result["data"]; ok {
		content := extractOpenAIContent(data)
		if content != "" {
			parsed := parsePolishResult(content)
			if parsed["title"] == "" {
				parsed["title"] = "润色结果"
			}
			return parsed, nil
		}
	}

	raw, _ := result["raw"].(string)
	parsed := parsePolishResult(raw)
	if parsed["title"] == "" {
		parsed["title"] = "润色结果"
	}
	return parsed, nil
}
