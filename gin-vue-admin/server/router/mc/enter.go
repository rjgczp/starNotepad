package mc

import api "github.com/flipped-aurora/gin-vue-admin/server/api/v1"

type RouterGroup struct{ McWorldRouter }

var mcworldApi = api.ApiGroupApp.McApiGroup.McWorldApi
