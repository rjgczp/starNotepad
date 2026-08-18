package system

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
)

func TestUploadAppReleaseFileAcceptsAPK(t *testing.T) {
	gin.SetMode(gin.TestMode)
	previousOssType := global.GVA_CONFIG.System.OssType
	previousStorePath := global.GVA_CONFIG.Local.StorePath
	previousPublicPath := global.GVA_CONFIG.Local.Path
	previousBaseURL := global.GVA_CONFIG.DuoRitual.PublicBaseURL
	t.Cleanup(func() {
		global.GVA_CONFIG.System.OssType = previousOssType
		global.GVA_CONFIG.Local.StorePath = previousStorePath
		global.GVA_CONFIG.Local.Path = previousPublicPath
		global.GVA_CONFIG.DuoRitual.PublicBaseURL = previousBaseURL
	})

	global.GVA_CONFIG.System.OssType = "local"
	global.GVA_CONFIG.Local.StorePath = t.TempDir()
	global.GVA_CONFIG.Local.Path = "uploads/file"
	global.GVA_CONFIG.DuoRitual.PublicBaseURL = "https://ai.xiaoyu.ski"

	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	file, err := writer.CreateFormFile("file", "情侣小屋_0.2.1.apk")
	require.NoError(t, err)
	_, err = file.Write([]byte("fake apk payload"))
	require.NoError(t, err)
	require.NoError(t, writer.WriteField("platform", "android"))
	require.NoError(t, writer.Close())

	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)
	context.Request = httptest.NewRequest(http.MethodPost, "/api/duoCall/admin/release/upload", &body)
	context.Request.Header.Set("Content-Type", writer.FormDataContentType())
	(&DuoCallApi{}).UploadAppReleaseFile(context)

	require.Equal(t, http.StatusOK, recorder.Code)
	require.Contains(t, recorder.Body.String(), "https://ai.xiaoyu.ski/uploads/file/duo-call/releases/")
	entries, err := os.ReadDir(filepath.Join(global.GVA_CONFIG.Local.StorePath, "duo-call", "releases"))
	require.NoError(t, err)
	require.Len(t, entries, 1)
}
