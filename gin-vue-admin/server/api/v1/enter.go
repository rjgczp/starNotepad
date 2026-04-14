package v1

import (
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/User"
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/aiAge"
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/example"
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/starNodeCore"
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/starNote"
	"github.com/flipped-aurora/gin-vue-admin/server/api/v1/system"
)

var ApiGroupApp = new(ApiGroup)

type ApiGroup struct {
	SystemApiGroup       system.ApiGroup
	ExampleApiGroup      example.ApiGroup
	UserApiGroup         User.ApiGroup
	StarNodeCoreApiGroup starNodeCore.ApiGroup
	StarNoteApiGroup     starNote.ApiGroup
	AiAgeApiGroup        aiAge.ApiGroup
}
