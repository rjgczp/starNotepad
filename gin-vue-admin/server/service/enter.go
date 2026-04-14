package service

import (
	"github.com/flipped-aurora/gin-vue-admin/server/service/User"
	"github.com/flipped-aurora/gin-vue-admin/server/service/aiAge"
	"github.com/flipped-aurora/gin-vue-admin/server/service/example"
	"github.com/flipped-aurora/gin-vue-admin/server/service/starNodeCore"
	"github.com/flipped-aurora/gin-vue-admin/server/service/starNote"
	"github.com/flipped-aurora/gin-vue-admin/server/service/system"
)

var ServiceGroupApp = new(ServiceGroup)

type ServiceGroup struct {
	SystemServiceGroup       system.ServiceGroup
	ExampleServiceGroup      example.ServiceGroup
	UserServiceGroup         User.ServiceGroup
	StarNodeCoreServiceGroup starNodeCore.ServiceGroup
	StarNoteServiceGroup     starNote.ServiceGroup
	AiAgeServiceGroup        aiAge.ServiceGroup
}
