package starNote

import (
	"errors"
	"math"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/common/response"
	"github.com/flipped-aurora/gin-vue-admin/server/service"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
)

var fileUploadAndDownloadService = service.ServiceGroupApp.ExampleServiceGroup.FileUploadAndDownloadService

var _ = response.Response{}

type UserFileApi struct{}

type minecraftPreviewResponse struct {
	WorldPath   string  `json:"worldPath"`
	WorldAbs    string  `json:"worldAbs"`
	GridSize    int     `json:"gridSize"`
	RegionCount int     `json:"regionCount"`
	Heights     [][]int `json:"heights"`
}

func normalizeMinecraftWorldPath(input string) (string, string, error) {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return "", "", errors.New("empty worldPath")
	}

	storeRoot := filepath.Clean(global.GVA_CONFIG.Local.StorePath)
	if !filepath.IsAbs(storeRoot) {
		absStoreRoot, absErr := filepath.Abs(storeRoot)
		if absErr != nil {
			return "", "", absErr
		}
		storeRoot = filepath.Clean(absStoreRoot)
	}
	if storeRoot == "." || storeRoot == "/" {
		return "", "", errors.New("invalid store path")
	}

	localURLPrefix := "/" + strings.Trim(global.GVA_CONFIG.Local.Path, "/")
	var absPath string
	if strings.HasPrefix(trimmed, localURLPrefix) {
		rel := strings.TrimPrefix(trimmed, localURLPrefix)
		rel = strings.TrimPrefix(rel, "/")
		absPath = filepath.Join(storeRoot, filepath.FromSlash(rel))
	} else if filepath.IsAbs(trimmed) {
		absPath = filepath.Clean(trimmed)
	} else {
		absPath = filepath.Join(storeRoot, filepath.FromSlash(trimmed))
	}
	absPath = filepath.Clean(absPath)

	if !strings.HasPrefix(absPath, storeRoot+string(filepath.Separator)) && absPath != storeRoot {
		return "", "", errors.New("worldPath out of local store scope")
	}

	relPath, err := filepath.Rel(storeRoot, absPath)
	if err != nil {
		return "", "", err
	}
	if relPath == "." || strings.HasPrefix(relPath, "..") {
		return "", "", errors.New("invalid world path")
	}

	worldURL := localURLPrefix + "/" + filepath.ToSlash(relPath)
	return absPath, worldURL, nil
}

func buildHeightMap(seed int, size int) [][]int {
	heights := make([][]int, size)
	for z := 0; z < size; z++ {
		row := make([]int, size)
		for x := 0; x < size; x++ {
			v := math.Sin(float64(seed+x*3)*0.17) + math.Cos(float64(seed-z*2)*0.13) + math.Sin(float64(x+z)*0.22)
			h := int(math.Round((v + 3.0) * 6.5))
			if h < 2 {
				h = 2
			}
			row[x] = h
		}
		heights[z] = row
	}
	return heights
}

// Upload 用户端上传文件/图片
// @Tags UserFile
// @Summary 用户端上传文件/图片
// @Security ApiKeyAuth
// @accept multipart/form-data
// @Produce application/json
// @Param file formData file true "上传文件"
// @Param classId formData int false "分类ID"
// @Param noSave query string false "是否保存到数据库(0保存/1不保存)" default(0)
// @Success 200 {object} response.Response{data=object,msg=string} "上传成功"
// @Router /ufile/upload [post]
func (ufa *UserFileApi) Upload(c *gin.Context) {
	noSave := c.DefaultQuery("noSave", "0")
	classID, _ := strconv.Atoi(c.DefaultPostForm("classId", "0"))

	_, header, err := c.Request.FormFile("file")
	if err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	file, err := fileUploadAndDownloadService.UploadFile(header, noSave, classID)
	if err != nil {
		global.GVA_LOG.Error("上传文件失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "上传文件失败",
		})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code": http.StatusOK,
		"data": gin.H{
			"file": file,
		},
		"message": "上传成功",
	})
}

// Download 用户端下载/访问文件
// @Tags UserFile
// @Summary 用户端下载/访问文件(通过id查询并跳转)
// @Security ApiKeyAuth
// @Produce application/json
// @Param id query int true "文件记录ID"
// @Success 302 {string} string "跳转到文件URL"
// @Router /ufile/download [get]
func (ufa *UserFileApi) Download(c *gin.Context) {
	idStr := c.Query("id")
	id64, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil || id64 == 0 {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	file, err := fileUploadAndDownloadService.FindFile(uint(id64))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
				"code":    http.StatusNotFound,
				"data":    gin.H{},
				"message": "资源不存在",
			})
			return
		}
		global.GVA_LOG.Error("获取文件失败!", zap.Error(err))
		c.AbortWithStatusJSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"data":    gin.H{},
			"message": "服务器内部错误",
		})
		return
	}
	if strings.TrimSpace(file.Url) == "" {
		c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
			"code":    http.StatusNotFound,
			"data":    gin.H{},
			"message": "资源不存在",
		})
		return
	}

	url := file.Url
	if global.GVA_CONFIG.System.OssType == "local" && strings.TrimSpace(file.Key) != "" {
		url = path.Join(global.GVA_CONFIG.Local.Path, file.Key)
	}
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		if !strings.HasPrefix(url, "/") {
			url = "/" + url
		}
	}

	c.Redirect(http.StatusFound, url)
}

// DownloadPath 支持路径式下载：/ufile/download/uploads/file/<filename>
// 仅用于本地存储（OssType=local）场景，直接返回文件内容。
// @Tags UserFile
// @Summary 用户端下载/访问文件(路径式)
// @Security ApiKeyAuth
// @Produce application/octet-stream
// @Param filepath path string true "文件路径(如 uploads/file/xxx.png)"
// @Success 200 {file} file "文件内容"
// @Router /ufile/download/{filepath} [get]
func (ufa *UserFileApi) DownloadPath(c *gin.Context) {
	if global.GVA_CONFIG.System.OssType != "local" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	// param 形如 "/uploads/file/xxx.png"
	raw := c.Param("filepath")
	if raw == "" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	cleaned := path.Clean("/" + strings.TrimSpace(raw))

	// 必须以 /uploads/file 开头（使用配置，避免写死）
	expectedPrefix := "/" + strings.Trim(global.GVA_CONFIG.Local.Path, "/")
	if cleaned == expectedPrefix {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}
	if !strings.HasPrefix(cleaned, expectedPrefix+"/") {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	filename := path.Base(cleaned)
	// 简单防御：禁止 path traversal / 非法字符
	if filename == "." || filename == "/" || strings.Contains(filename, "..") || strings.ContainsAny(filename, `\\/:*?"<>|`) {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"data":    gin.H{},
			"message": "参数错误",
		})
		return
	}

	abs := filepath.Join(global.GVA_CONFIG.Local.StorePath, filename)
	// gin 会处理文件不存在时的 404，这里保持返回风格一致
	if _, err := filepath.Abs(abs); err != nil {
		c.AbortWithStatusJSON(http.StatusNotFound, gin.H{
			"code":    http.StatusNotFound,
			"data":    gin.H{},
			"message": "资源不存在",
		})
		return
	}

	c.File(abs)
}

// MinecraftPreview 返回 Minecraft 世界简化预览数据（高度图）
// @Tags UserFile
// @Summary 获取 Minecraft 世界预览数据
// @Produce application/json
// @Param worldPath query string true "世界目录路径(绝对路径或本地URL路径)"
// @Success 200 {object} response.Response{data=object,msg=string} "获取成功"
// @Router /ufile/minecraft/preview [get]
func (ufa *UserFileApi) MinecraftPreview(c *gin.Context) {
	if global.GVA_CONFIG.System.OssType != "local" {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"code": http.StatusBadRequest, "data": gin.H{}, "message": "仅支持本地存储"})
		return
	}

	worldPath := c.Query("worldPath")
	worldAbs, worldURL, err := normalizeMinecraftWorldPath(worldPath)
	if err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"code": http.StatusBadRequest, "data": gin.H{}, "message": "参数错误"})
		return
	}

	info, err := os.Stat(worldAbs)
	if err != nil || !info.IsDir() {
		c.AbortWithStatusJSON(http.StatusNotFound, gin.H{"code": http.StatusNotFound, "data": gin.H{}, "message": "世界目录不存在"})
		return
	}

	if _, err = os.Stat(filepath.Join(worldAbs, "level.dat")); err != nil {
		c.AbortWithStatusJSON(http.StatusBadRequest, gin.H{"code": http.StatusBadRequest, "data": gin.H{}, "message": "该目录不是有效 Minecraft 世界"})
		return
	}

	regionDir := filepath.Join(worldAbs, "region")
	regionCount := 0
	seed := 17
	for _, ch := range strings.ToLower(strings.TrimSpace(worldAbs)) {
		seed = seed*31 + int(ch)
	}

	entries, err := os.ReadDir(regionDir)
	if err == nil {
		for _, entry := range entries {
			if entry.IsDir() {
				continue
			}
			name := strings.ToLower(strings.TrimSpace(entry.Name()))
			if !strings.HasSuffix(name, ".mca") {
				continue
			}
			regionCount++
			for _, ch := range name {
				seed = seed*31 + int(ch)
			}
		}
	}

	preview := minecraftPreviewResponse{
		WorldPath:   worldURL,
		WorldAbs:    worldAbs,
		GridSize:    24,
		RegionCount: regionCount,
		Heights:     buildHeightMap(seed, 24),
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    gin.H{"preview": preview},
		"message": "获取成功",
	})
}

// ActiveWorldResponse represents the current active world configuration
type ActiveWorldResponse struct {
	WorldPath string `json:"worldPath"`
	MapURL    string `json:"mapUrl"`
	IsActive  bool   `json:"isActive"`
}

// SetActiveWorldRequest represents the request to set active world
type SetActiveWorldRequest struct {
	WorldPath string `json:"worldPath" binding:"required"`
	MapURL    string `json:"mapUrl"`
}

// GetActiveWorld returns the current active world configuration
func (ufa *UserFileApi) GetActiveWorld(c *gin.Context) {
	// For now, return environment variable or default configuration
	// In a real implementation, this would query the database
	worldPath := os.Getenv("MINECRAFT_ACTIVE_WORLD_PATH")
	if worldPath == "" {
		worldPath = "/Users/charles/Documents/notepad/gin-vue-admin/server/uploads/file/5dc8ac4829e99f6b5d333881a92c7f24_20260429141901/新的世界"
	}

	mapURL := os.Getenv("MINECRAFT_MAP_URL")
	if mapURL == "" {
		mapURL = "http://localhost:8100"
	}

	response := ActiveWorldResponse{
		WorldPath: worldPath,
		MapURL:    mapURL,
		IsActive:  worldPath != "",
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    response,
		"message": "获取成功",
	})
}

// SetActiveWorld sets the current active world configuration
func (ufa *UserFileApi) SetActiveWorld(c *gin.Context) {
	var req SetActiveWorldRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "请求参数错误: " + err.Error(),
		})
		return
	}

	// Validate world path
	absPath, _, err := normalizeMinecraftWorldPath(req.WorldPath)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "世界路径无效: " + err.Error(),
		})
		return
	}

	// Check if world directory exists and contains level.dat
	levelDatPath := filepath.Join(absPath, "level.dat")
	if _, err := os.Stat(levelDatPath); os.IsNotExist(err) {
		c.JSON(http.StatusBadRequest, gin.H{
			"code":    http.StatusBadRequest,
			"message": "指定路径不是有效的Minecraft世界目录（缺少level.dat文件）",
		})
		return
	}

	// Create active world symlink for BlueMap
	activeWorldDir := "/Users/charles/Documents/notepad/bluemap/active-world"

	// Remove existing symlink if it exists
	os.RemoveAll(activeWorldDir)

	// Create new symlink
	if err := os.Symlink(absPath, activeWorldDir); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{
			"code":    http.StatusInternalServerError,
			"message": "创建活跃世界链接失败: " + err.Error(),
		})
		return
	}

	// Set default map URL if not provided
	if req.MapURL == "" {
		req.MapURL = "http://localhost:8100"
	}

	// In a real implementation, this would save to database
	// For now, we'll just return success
	response := ActiveWorldResponse{
		WorldPath: req.WorldPath,
		MapURL:    req.MapURL,
		IsActive:  true,
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    http.StatusOK,
		"data":    response,
		"message": "活跃世界设置成功",
	})
}
