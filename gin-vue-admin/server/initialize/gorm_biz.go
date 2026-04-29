package initialize

import (
	"github.com/flipped-aurora/gin-vue-admin/server/global"
	"github.com/flipped-aurora/gin-vue-admin/server/model/mc"
	"github.com/flipped-aurora/gin-vue-admin/server/model/starNote"
	"github.com/flipped-aurora/gin-vue-admin/server/model/system"
)

func bizModel() error {
	db := global.GVA_DB
	err := db.AutoMigrate(starNote.UserAccount{}, starNote.NoteModel{}, starNote.StarTag{}, starNote.UserTag{}, starNote.UserLoginLog{}, starNote.UserAIPolishLog{}, starNote.UserEmailCode{}, starNote.UserDevice{}, starNote.HistoryDay{}, starNote.StarColor{}, starNote.NoteCategory{}, starNote.Provider{}, system.UserBlog_config{}, mc.McWorld{})
	if err != nil {
		return err
	}
	return nil
}
