package starNote

import "github.com/flipped-aurora/gin-vue-admin/server/service"

type ApiGroup struct {
	UserAccountApi
	NoteModelApi
	StarTagApi
	HistoryDayApi
	UserFileApi
	StarColorApi
	NoteCategoryApi
	ProviderApi
}

var (
	uaService         = service.ServiceGroupApp.StarNoteServiceGroup.UserAccountService
	evtService        = service.ServiceGroupApp.StarNoteServiceGroup.NoteModelService
	stService         = service.ServiceGroupApp.StarNoteServiceGroup.StarTagService
	hdService         = service.ServiceGroupApp.StarNoteServiceGroup.HistoryDayService
	scService         = service.ServiceGroupApp.StarNoteServiceGroup.StarColorService
	ncService         = service.ServiceGroupApp.StarNoteServiceGroup.NoteCategoryService
	aiProviderService = service.ServiceGroupApp.StarNoteServiceGroup.ProviderService
)
