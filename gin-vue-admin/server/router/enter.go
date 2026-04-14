package router

import (
	"github.com/flipped-aurora/gin-vue-admin/server/router/User"
	"github.com/flipped-aurora/gin-vue-admin/server/router/aiAge"
	"github.com/flipped-aurora/gin-vue-admin/server/router/example"
	"github.com/flipped-aurora/gin-vue-admin/server/router/starNodeCore"
	"github.com/flipped-aurora/gin-vue-admin/server/router/starNote"
	"github.com/flipped-aurora/gin-vue-admin/server/router/system"
)

var RouterGroupApp = new(RouterGroup)

type RouterGroup struct {
	System       system.RouterGroup
	Example      example.RouterGroup
	User         User.RouterGroup
	StarNodeCore starNodeCore.RouterGroup
	StarNote     starNote.RouterGroup
	AiAge        aiAge.RouterGroup
}
