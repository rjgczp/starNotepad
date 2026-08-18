package system

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/middleware"
	"github.com/gin-gonic/gin"
)

type DuoCallRouter struct{}

func (r *DuoCallRouter) InitDuoCallRouter(private, public *gin.RouterGroup) {
	admin := private.Group("duoCall")
	admin.GET("admin/list", duoCallApi.AdminList)
	admin.POST("admin/identity", duoCallApi.SaveIdentity)
	admin.POST("admin/status", duoCallApi.SaveStatus)
	admin.DELETE("admin/status", duoCallApi.DeleteStatus)
	admin.POST("admin/album", duoCallApi.SaveAlbum)
	admin.DELETE("admin/album", duoCallApi.DeleteAlbum)
	admin.POST("admin/anniversary", duoCallApi.SaveAnniversary)
	admin.DELETE("admin/anniversary", duoCallApi.DeleteAnniversary)
	admin.POST("admin/release/upload", duoCallApi.UploadAppReleaseFile)
	admin.POST("admin/release", duoCallApi.SaveAppRelease)
	admin.DELETE("admin/release", duoCallApi.DeleteAppRelease)
	admin.GET("admin/ritual", duoCallApi.AdminRitual)
	admin.POST("admin/ritual/setting", duoCallApi.SaveDailySetting)
	admin.POST("admin/ritual/fallback", duoCallApi.SaveFallbackQuestion)
	admin.DELETE("admin/ritual/fallback", duoCallApi.DeleteFallbackQuestion)
	admin.POST("admin/ritual/regenerate", duoCallApi.RegenerateDailyQuestion)
	admin.POST("admin/wechat/recipient", duoCallApi.SaveWechatRecipient)
	admin.POST("admin/wechat/test", duoCallApi.TestWechatRecipient)
	admin.POST("admin/wechat/retry", duoCallApi.RetryWechatPush)
	group := public.Group("duoCall")
	group.Use(middleware.DuoPublicCORS())
	group.OPTIONS("/*path", func(c *gin.Context) { c.Status(204) })
	group.POST("login", middleware.DuoLoginRateLimit(12, time.Minute), duoCallApi.Login)
	group.GET("update", duoCallApi.CheckAppUpdate)
	group.GET("ws", duoCallApi.WebSocket)
	group.GET("bootstrap", duoCallApi.Bootstrap)
	group.PUT("profile", duoCallApi.UpdateProfile)
	group.POST("profile/avatar", duoCallApi.UploadAvatar)
	group.GET("messages", duoCallApi.History)
	group.POST("messages", duoCallApi.Send)
	group.POST("messages/image", duoCallApi.UploadImage)
	group.POST("messages/read", duoCallApi.Read)
	group.GET("messages/wechat", duoCallApi.ChatWechatPreference)
	group.PUT("messages/wechat", duoCallApi.UpdateChatWechatPreference)
	group.GET("messages/unread", duoCallApi.Unread)
	group.POST("status", duoCallApi.SetStatus)
	group.GET("album", duoCallApi.Albums)
	group.POST("album/upload", duoCallApi.UploadAlbum)
	group.DELETE("album", duoCallApi.DeleteOwnAlbum)
	group.GET("anniversaries", duoCallApi.Anniversaries)
	group.GET("notes", duoCallApi.Notes)
	group.POST("notes", duoCallApi.SendNote)
	group.GET("tree", duoCallApi.Tree)
	group.POST("miss-you", duoCallApi.SendMissYou)
	group.GET("miss-you/pending", duoCallApi.PendingMissYou)
	group.POST("miss-you/:id/ack", duoCallApi.AcknowledgeMissYou)
	group.GET("daily/today", duoCallApi.DailyToday)
	group.POST("daily/reply", duoCallApi.SaveDailyReply)
	group.GET("daily/history", duoCallApi.DailyHistory)
}
