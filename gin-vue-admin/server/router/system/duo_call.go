package system

import "github.com/gin-gonic/gin"

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
	group := public.Group("duoCall")
	group.POST("login", duoCallApi.Login)
	group.GET("ws", duoCallApi.WebSocket)
	group.GET("bootstrap", duoCallApi.Bootstrap)
	group.GET("messages", duoCallApi.History)
	group.POST("messages", duoCallApi.Send)
	group.POST("messages/image", duoCallApi.UploadImage)
	group.POST("messages/read", duoCallApi.Read)
	group.GET("messages/unread", duoCallApi.Unread)
	group.POST("status", duoCallApi.SetStatus)
	group.GET("album", duoCallApi.Albums)
	group.POST("album/upload", duoCallApi.UploadAlbum)
	group.DELETE("album", duoCallApi.DeleteOwnAlbum)
	group.GET("anniversaries", duoCallApi.Anniversaries)
	group.GET("notes", duoCallApi.Notes)
	group.POST("notes", duoCallApi.SendNote)
}
