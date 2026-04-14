package starNote

import (
	"errors"
	"net/http"
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
