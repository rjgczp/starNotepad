package starNote

import api "github.com/flipped-aurora/gin-vue-admin/server/api/v1"

type RouterGroup struct {
	UserAccountRouter
	NoteModelRouter
	StarTagRouter
	HistoryDayRouter
	UserFileRouter
	StarColorRouter
	NoteCategoryRouter
	ProviderRouter
}

var (
	uaApi         = api.ApiGroupApp.StarNoteApiGroup.UserAccountApi
	evtApi        = api.ApiGroupApp.StarNoteApiGroup.NoteModelApi
	stApi         = api.ApiGroupApp.StarNoteApiGroup.StarTagApi
	hdApi         = api.ApiGroupApp.StarNoteApiGroup.HistoryDayApi
	ufApi         = api.ApiGroupApp.StarNoteApiGroup.UserFileApi
	scApi         = api.ApiGroupApp.StarNoteApiGroup.StarColorApi
	ncApi         = api.ApiGroupApp.StarNoteApiGroup.NoteCategoryApi
	aiProviderApi = api.ApiGroupApp.StarNoteApiGroup.ProviderApi
)
