package system

import (
	"errors"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/flipped-aurora/gin-vue-admin/server/global"
	model "github.com/flipped-aurora/gin-vue-admin/server/model/system"
	"github.com/gin-gonic/gin"
	"github.com/stretchr/testify/require"
)

func TestDuoProfileNameValidation(t *testing.T) {
	name, err := duoProfileName("  小海  ")
	require.NoError(t, err)
	require.Equal(t, "小海", name)

	_, err = duoProfileName("   ")
	require.Error(t, err)
	_, err = duoProfileName(strings.Repeat("海", 25))
	require.Error(t, err)
}

func TestDuoLoginRejectsOversizedBodyBeforeDatabaseAccess(t *testing.T) {
	gin.SetMode(gin.TestMode)
	recorder := httptest.NewRecorder()
	context, _ := gin.CreateTestContext(recorder)
	body := `{"key":"` + strings.Repeat("x", 5000) + `"}`
	context.Request = httptest.NewRequest(http.MethodPost, "/api/duoCall/login", strings.NewReader(body))
	context.Request.Header.Set("Content-Type", "application/json")

	(&DuoCallApi{}).Login(context)

	require.Equal(t, http.StatusRequestEntityTooLarge, recorder.Code)
	require.Contains(t, recorder.Body.String(), "请求体过大")
}

func TestDuoQixiInvitationTargetsConfiguredMember(t *testing.T) {
	t.Setenv("DUO_QIXI_INVITATION_SLOT", "2")
	require.False(t, duoQixiInvitationForSlot(1))
	require.True(t, duoQixiInvitationForSlot(2))

	t.Setenv("DUO_QIXI_INVITATION_SLOT", "disabled")
	require.False(t, duoQixiInvitationForSlot(2))
}

func TestDuoReleaseUploadPolicy(t *testing.T) {
	require.True(t, duoReleaseExtensionAllowed("android", ".apk"))
	require.True(t, duoReleaseExtensionAllowed("android", ".AAB"))
	require.False(t, duoReleaseExtensionAllowed("android", ".dmg"))
	require.True(t, duoReleaseExtensionAllowed("desktop", ".msi"))
	require.False(t, duoReleaseExtensionAllowed("desktop", ".apk"))

	previous := global.GVA_CONFIG.DuoRitual.PublicBaseURL
	t.Cleanup(func() { global.GVA_CONFIG.DuoRitual.PublicBaseURL = previous })
	global.GVA_CONFIG.DuoRitual.PublicBaseURL = "https://ai.xiaoyu.ski/"
	url, err := duoReleaseDownloadURL("/uploads/file/duo-call/releases/app.apk")
	require.NoError(t, err)
	require.Equal(t, "https://ai.xiaoyu.ski/uploads/file/duo-call/releases/app.apk", url)

	_, err = duoReleaseDownloadURL("/tmp/app.apk")
	require.Error(t, err)
}

func TestDuoIdentitySafeViewIncludesConfiguredStatus(t *testing.T) {
	statusID := uint(7)
	view := duoIdentitySafeView(model.DuoCallIdentity{
		Slot: 2, DisplayName: "小月", AvatarURL: "/uploads/duo-call/avatar/moon.png",
		StatusID: &statusID, EncryptedKey: "must-not-leak",
	}, map[uint]model.DuoCallStatus{
		7: {GVA_MODEL: global.GVA_MODEL{ID: 7}, Label: "今天很开心", Emoji: "☀️"},
	})

	require.Equal(t, uint(2), view.Slot)
	require.Equal(t, "小月", view.DisplayName)
	require.Equal(t, statusID, *view.StatusID)
	require.NotNil(t, view.Status)
	require.Equal(t, "今天很开心", view.Status.Label)
	require.Equal(t, "☀️", view.Status.Emoji)
}

func TestDuoMediaURLCanonicalizesLegacyAPIPath(t *testing.T) {
	previousStore := global.GVA_CONFIG.Local.StorePath
	previousPrefix := global.GVA_CONFIG.System.RouterPrefix
	t.Cleanup(func() {
		global.GVA_CONFIG.Local.StorePath = previousStore
		global.GVA_CONFIG.System.RouterPrefix = previousPrefix
	})
	global.GVA_CONFIG.Local.StorePath = "uploads/file"
	global.GVA_CONFIG.System.RouterPrefix = "/api"

	require.Equal(t, "/uploads/file/duo-call/avatar/moon.png",
		duoMediaURL("/api/uploads/file/duo-call/avatar/moon.png"))
	require.Equal(t, "/uploads/file/duo-call/chat.png",
		duoMediaURL("uploads/file/duo-call/chat.png"))
	require.Equal(t, "https://cdn.example/avatar.png",
		duoMediaURL("https://cdn.example/avatar.png"))
}

func TestLatestDuoNotesKeepsNewestPerMember(t *testing.T) {
	items := latestDuoNotesByMember([]model.DuoCallNote{
		{GVA_MODEL: global.GVA_MODEL{ID: 5}, SenderSlot: 1, Content: "我的最新留言"},
		{GVA_MODEL: global.GVA_MODEL{ID: 4}, SenderSlot: 1, Content: "我的旧留言"},
		{GVA_MODEL: global.GVA_MODEL{ID: 3}, SenderSlot: 2, Content: "TA 的最新留言"},
	})
	require.Len(t, items, 2)
	require.EqualValues(t, 5, items[0].ID)
	require.EqualValues(t, 3, items[1].ID)
}

func TestRemoveDuoAvatarFileStaysInControlledDirectory(t *testing.T) {
	previous := global.GVA_CONFIG.Local.StorePath
	t.Cleanup(func() { global.GVA_CONFIG.Local.StorePath = previous })

	storePath := t.TempDir()
	global.GVA_CONFIG.Local.StorePath = storePath
	avatarDir := filepath.Join(storePath, "duo-call", "avatar")
	require.NoError(t, os.MkdirAll(avatarDir, 0755))
	avatarPath := filepath.Join(avatarDir, "old.png")
	require.NoError(t, os.WriteFile(avatarPath, []byte("avatar"), 0644))

	removeDuoAvatarFile("/" + strings.Trim(storePath, "/") + "/duo-call/avatar/old.png")
	_, err := os.Stat(avatarPath)
	require.True(t, errors.Is(err, os.ErrNotExist))

	outsidePath := filepath.Join(storePath, "keep.png")
	require.NoError(t, os.WriteFile(outsidePath, []byte("keep"), 0644))
	removeDuoAvatarFile("/uncontrolled/keep.png")
	_, err = os.Stat(outsidePath)
	require.NoError(t, err)
}
