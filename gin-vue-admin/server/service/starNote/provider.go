package starNote

import (
	"bufio"
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

func (aiProviderService *ProviderService) PublicChatWithAI(ctx context.Context, messages []map[string]string) (string, error) {
	return aiProviderService.chatCompletion(ctx, messages, nil)
}

func (aiProviderService *ProviderService) PublicChatWithAIStream(ctx context.Context, messages []map[string]string, onToken func(string) error) error {
	activeProvider, err := getActiveProvider(ctx)
	if err != nil {
		return err
	}
	decryptProviderEntity(&activeProvider)

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

	baseURL := ""
	if activeProvider.BaseUrl != nil {
		baseURL = strings.TrimSpace(*activeProvider.BaseUrl)
	}
	baseURL = strings.TrimRight(baseURL, "/")
	if baseURL == "" {
		return errors.New("未配置有效的 AI 服务地址")
	}

	apiKey := ""
	if activeProvider.ApiKey != nil {
		apiKey = strings.TrimSpace(*activeProvider.ApiKey)
	}
	if strings.TrimSpace(apiKey) == "" {
		return errors.New("未配置有效的 AI 服务密钥")
	}

	body := map[string]interface{}{
		"model":    model,
		"messages": messages,
		"stream":   true,
	}
	headers := map[string]string{
		"Authorization": "Bearer " + apiKey,
		"Content-Type":  "application/json",
		"Accept":        "text/event-stream",
	}

	resp, err := requestUtils.HttpRequestWithContext(ctx, baseURL+"/chat/completions", http.MethodPost, headers, nil, body)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode >= http.StatusBadRequest {
		bodyBytes, _ := io.ReadAll(resp.Body)
		if strings.TrimSpace(string(bodyBytes)) != "" {
			return errors.New(strings.TrimSpace(string(bodyBytes)))
		}
		return errors.New("AI服务调用失败")
	}

	scanner := bufio.NewScanner(resp.Body)
	buf := make([]byte, 0, 64*1024)
	scanner.Buffer(buf, 1024*1024)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || !strings.HasPrefix(line, "data:") {
			continue
		}
		payload := strings.TrimSpace(strings.TrimPrefix(line, "data:"))
		if payload == "[DONE]" {
			return nil
		}
		var chunk map[string]interface{}
		if err := json.Unmarshal([]byte(payload), &chunk); err != nil {
			continue
		}
		for _, token := range extractOpenAIStreamContent(chunk) {
			if token == "" {
				continue
			}
			if err := onToken(token); err != nil {
				return err
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	return nil
}

// chatCompletion 统一的 chat/completions 调用入口，extra 可注入 temperature 等可选参数。
func (aiProviderService *ProviderService) chatCompletion(ctx context.Context, messages []map[string]string, extra map[string]interface{}) (string, error) {
	activeProvider, err := getActiveProvider(ctx)
	if err != nil {
		return "", err
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

	body := map[string]interface{}{
		"model":    model,
		"messages": messages,
	}
	for k, v := range extra {
		body[k] = v
	}

	invokeReq := starNoteReq.ProviderInvokeReq{
		Path:   "/chat/completions",
		Method: http.MethodPost,
		Body:   body,
	}

	result, err := aiProviderService.InvokeActiveProvider(ctx, invokeReq)
	if err != nil {
		return "", err
	}

	if statusCode, ok := result["statusCode"].(int); ok && statusCode >= http.StatusBadRequest {
		if data, ok := result["data"].(map[string]interface{}); ok {
			if errObj, ok := data["error"].(map[string]interface{}); ok {
				if msg, ok := errObj["message"].(string); ok && strings.TrimSpace(msg) != "" {
					return "", errors.New(msg)
				}
			}
		}
		if raw, ok := result["raw"].(string); ok && strings.TrimSpace(raw) != "" {
			return "", errors.New(raw)
		}
		return "", errors.New("AI服务调用失败")
	}

	if data, ok := result["data"]; ok {
		if content := extractOpenAIContent(data); content != "" {
			return content, nil
		}
	}

	raw, _ := result["raw"].(string)
	return strings.TrimSpace(raw), nil
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

func extractOpenAIStreamContent(data interface{}) []string {
	m, ok := data.(map[string]interface{})
	if !ok {
		return nil
	}
	choices, ok := m["choices"].([]interface{})
	if !ok || len(choices) == 0 {
		return nil
	}
	result := make([]string, 0, len(choices))
	for _, choice := range choices {
		choiceMap, ok := choice.(map[string]interface{})
		if !ok {
			continue
		}
		delta, ok := choiceMap["delta"].(map[string]interface{})
		if !ok {
			continue
		}
		content, _ := delta["content"].(string)
		if content != "" {
			result = append(result, content)
		}
	}
	return result
}

// RunAgent 把用户一句话指令翻译为结构化的 action 列表。
// 返回值: reply 为给用户的自然语言回复，actions 为待前端执行的结构化指令数组。
func (aiProviderService *ProviderService) RunAgent(ctx context.Context, instruction string, notes []starNoteReq.AgentNoteContext) (map[string]interface{}, error) {
	contextBuilder := strings.Builder{}
	if len(notes) > 0 {
		contextBuilder.WriteString("以下是用户当前的笔记列表(JSON)，可作为整理/重构/导出的依据：\n")
		if b, err := json.Marshal(notes); err == nil {
			contextBuilder.Write(b)
		}
	} else {
		contextBuilder.WriteString("用户当前没有提供笔记上下文。")
	}

	systemPrompt := "你是“星记事”笔记应用的 AI Agent 助手。你的唯一任务是把用户的一句话指令转换为结构化操作。\n" +
		"【输出格式 - 必须严格遵守】\n" +
		"只输出一个合法的 JSON 对象，不要输出任何解释、前后缀文字或 Markdown 代码块标记(```）。\n" +
		"顶层结构: {\"reply\": \"给用户的简短中文回复\", \"actions\": [操作对象数组]}。\n" +
		"reply 必须是非空的中文字符串；actions 必须是数组（无操作时为空数组 []）。\n" +
		"【actions 中每个操作对象的类型与字段】\n" +
		"- create_note: {\"type\":\"create_note\",\"title\":\"标题\",\"content\":\"正文\",\"category\":\"可选分类名\"}\n" +
		"- update_note: {\"type\":\"update_note\",\"id\":笔记ID(整数),\"title\":\"新标题\",\"content\":\"新正文\"}\n" +
		"- merge_notes: {\"type\":\"merge_notes\",\"sourceIds\":[整数ID...],\"title\":\"合并后标题\",\"content\":\"合并后正文\"}\n" +
		"- categorize: {\"type\":\"categorize\",\"id\":笔记ID(整数),\"category\":\"分类名\"}\n" +
		"- export: {\"type\":\"export\",\"format\":\"markdown\",\"noteIds\":[整数ID...],\"title\":\"导出文件标题\",\"content\":\"要导出的完整文本\"}\n" +
		"【规则】\n" +
		"1. id 等字段必须使用上下文笔记里给出的真实 id（整数），不要编造。\n" +
		"2. 涉及整理/重构/合并/导出时，content 要给出完整、可直接保存的内容。\n" +
		"3. export 操作必须把要导出的内容写进 content 字段。\n" +
		"4. 用户只是闲聊或无需任何操作时，actions 返回空数组 []，并在 reply 中正常回应。\n" +
		"5. 再次强调：只返回 JSON，不要有任何额外字符。"

	messages := []map[string]string{
		{"role": "system", "content": systemPrompt},
		{"role": "user", "content": "用户指令：" + instruction + "\n\n" + contextBuilder.String()},
	}

	// 低温度 + 期望 JSON 输出，提升结构化结果的稳定性。
	raw, err := aiProviderService.chatCompletion(ctx, messages, map[string]interface{}{
		"temperature": 0.2,
	})
	if err != nil {
		return nil, err
	}

	parsed := parseAgentResult(raw)
	return parsed, nil
}

// parseAgentResult 解析 LLM 返回的 JSON，做容错处理。
func parseAgentResult(raw string) map[string]interface{} {
	trimmed := strings.TrimSpace(raw)
	// 剥离可能存在的 ```json ... ``` 包裹
	if strings.HasPrefix(trimmed, "```") {
		trimmed = strings.TrimPrefix(trimmed, "```json")
		trimmed = strings.TrimPrefix(trimmed, "```")
		trimmed = strings.TrimSuffix(trimmed, "```")
		trimmed = strings.TrimSpace(trimmed)
	}

	result := map[string]interface{}{
		"reply":   "",
		"actions": []interface{}{},
	}

	var obj map[string]interface{}
	if json.Unmarshal([]byte(trimmed), &obj) == nil {
		if v, ok := obj["reply"].(string); ok {
			result["reply"] = strings.TrimSpace(v)
		}
		if v, ok := obj["actions"].([]interface{}); ok {
			result["actions"] = v
		}
		if strings.TrimSpace(result["reply"].(string)) == "" {
			result["reply"] = "已为你处理。"
		}
		return result
	}

	// 解析失败时降级为纯文本回复
	if trimmed == "" {
		trimmed = "抱歉，我没有理解你的指令，请换个说法再试一次。"
	}
	result["reply"] = trimmed
	return result
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
