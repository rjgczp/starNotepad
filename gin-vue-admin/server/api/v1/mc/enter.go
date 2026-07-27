package mc

import "github.com/flipped-aurora/gin-vue-admin/server/service"

type ApiGroup struct{ McWorldApi }

var mcworldService = service.ServiceGroupApp.McServiceGroup.McWorldService
