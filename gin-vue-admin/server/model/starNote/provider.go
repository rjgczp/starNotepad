
// 自动生成模板Provider
package starNote
import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// AI供应商 结构体  Provider
type Provider struct {
    global.GVA_MODEL
  ProviderName  *string `json:"providerName" form:"providerName" gorm:"comment:提供商名称 (如 "mimo", "deepseek");column:provider_name;" binding:"required"`  //提供商名称
  BaseUrl  *string `json:"baseUrl" form:"baseUrl" gorm:"comment:API 地址 (如 https://api.xiaomimimo.com/v1);column:base_url;" binding:"required"`  //API地址
  ApiKey  *string `json:"apiKey" form:"apiKey" gorm:"comment:密钥 (建议加密存储);column:api_key;"`  //密钥
  IsActive  *bool `json:"isActive" form:"isActive" gorm:"comment:当前是否启用该供应商;column:is_active;"`  //是否启用
  ConfigJson  *string `json:"configJson" form:"configJson" gorm:"comment:存储特定参数 (如 max_tokens, model_name);column:config_;"`  //配置参数
}


// TableName AI供应商 Provider自定义表名 t_provider
func (Provider) TableName() string {
    return "t_provider"
}





