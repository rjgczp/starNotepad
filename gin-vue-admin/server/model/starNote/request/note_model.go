package request

import (
	"time"

	"github.com/flipped-aurora/gin-vue-admin/server/model/common/request"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
)

type NoteModelSearch struct {
	CreatedAtRange []time.Time `json:"createdAtRange" form:"createdAtRange[]"`
	UserName       string      `json:"userName" form:"userName"`
	Title          string      `json:"title" form:"title"`
	Content        string      `json:"content" form:"content"`
	request.PageInfo
}

type UserPolishReq struct {
	Text string `json:"text" form:"text" binding:"required"`
}

type UserNoteSyncPullReq struct {
	LastSyncAt *time.Time `json:"lastSyncAt" form:"lastSyncAt"`
}

type UserNoteEntitySyncPush struct {
	Upserts   []starNote.NoteModel `json:"upserts" form:"upserts"`
	DeletedID []uint               `json:"deletedIds" form:"deletedIds"`
}

type UserCategoryEntitySyncPush struct {
	Upserts   []starNote.NoteCategory `json:"upserts" form:"upserts"`
	DeletedID []uint                  `json:"deletedIds" form:"deletedIds"`
}

type UserColorEntitySyncPush struct {
	Upserts   []starNote.StarColor `json:"upserts" form:"upserts"`
	DeletedID []uint               `json:"deletedIds" form:"deletedIds"`
}

type UserNoteSyncPushReq struct {
	Notes      UserNoteEntitySyncPush     `json:"notes" form:"notes"`
	Categories UserCategoryEntitySyncPush `json:"categories" form:"categories"`
	Colors     UserColorEntitySyncPush    `json:"colors" form:"colors"`

	Upserts   []starNote.NoteModel `json:"upserts,omitempty" form:"upserts"`
	DeletedID []uint               `json:"deletedIds,omitempty" form:"deletedIds"`
}

type UserNoteDeletedItem struct {
	ID        uint       `json:"id"`
	DeletedAt *time.Time `json:"deletedAt"`
}
