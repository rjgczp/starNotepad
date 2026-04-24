package crypto

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"errors"
	"io"
	"strings"
	"sync"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
)

// 加密结果前缀，用于区分旧的明文数据，便于兼容历史数据及幂等处理。
const encryptedPrefix = "enc:v1:"

var (
	gcmOnce    sync.Once
	gcmCipher  cipher.AEAD
	gcmInitErr error
)

// initGCM 使用 jwt.signing-key 派生 32 字节密钥，构造 AES-256-GCM。
// 复用已有配置避免新增字段；若 signing-key 为空则返回错误。
func initGCM() {
	key := ""
	if global.GVA_CONFIG.JWT.SigningKey != "" {
		key = global.GVA_CONFIG.JWT.SigningKey
	}
	if key == "" {
		gcmInitErr = errors.New("jwt.signing-key 为空，无法派生字段加密密钥")
		return
	}
	sum := sha256.Sum256([]byte(key))
	block, err := aes.NewCipher(sum[:])
	if err != nil {
		gcmInitErr = err
		return
	}
	aead, err := cipher.NewGCM(block)
	if err != nil {
		gcmInitErr = err
		return
	}
	gcmCipher = aead
}

func getAEAD() (cipher.AEAD, error) {
	gcmOnce.Do(initGCM)
	if gcmInitErr != nil {
		return nil, gcmInitErr
	}
	return gcmCipher, nil
}

// IsEncrypted 判断给定字符串是否为密文（带有固定前缀）。
func IsEncrypted(s string) bool {
	return strings.HasPrefix(s, encryptedPrefix)
}

// EncryptString 对明文字符串进行加密；若已加密或为空字符串则原样返回。
func EncryptString(plain string) (string, error) {
	if plain == "" || IsEncrypted(plain) {
		return plain, nil
	}
	aead, err := getAEAD()
	if err != nil {
		return "", err
	}
	nonce := make([]byte, aead.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", err
	}
	ct := aead.Seal(nil, nonce, []byte(plain), nil)
	payload := append(nonce, ct...)
	return encryptedPrefix + base64.StdEncoding.EncodeToString(payload), nil
}

// DecryptString 对密文字符串进行解密；若无前缀（旧明文）则原样返回，保证向后兼容。
func DecryptString(value string) (string, error) {
	if value == "" || !IsEncrypted(value) {
		return value, nil
	}
	aead, err := getAEAD()
	if err != nil {
		return value, err
	}
	raw, err := base64.StdEncoding.DecodeString(strings.TrimPrefix(value, encryptedPrefix))
	if err != nil {
		return value, err
	}
	ns := aead.NonceSize()
	if len(raw) < ns {
		return value, errors.New("密文长度异常")
	}
	nonce, ct := raw[:ns], raw[ns:]
	plain, err := aead.Open(nil, nonce, ct, nil)
	if err != nil {
		return value, err
	}
	return string(plain), nil
}

// EncryptStringPtr 针对 *string 字段的便捷包装。
func EncryptStringPtr(p *string) error {
	if p == nil || *p == "" {
		return nil
	}
	enc, err := EncryptString(*p)
	if err != nil {
		return err
	}
	*p = enc
	return nil
}

// DecryptStringPtr 针对 *string 字段的便捷包装；解密失败时保留原值。
func DecryptStringPtr(p *string) {
	if p == nil || *p == "" {
		return
	}
	if dec, err := DecryptString(*p); err == nil {
		*p = dec
	}
}
