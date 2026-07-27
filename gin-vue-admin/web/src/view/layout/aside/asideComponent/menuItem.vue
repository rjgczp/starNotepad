<template>
  <el-menu-item
    :index="routerInfo.name"
    :style="{
          height: sideHeight
        }"
  >
    <template v-if="routerInfo.meta.icon">
      <i class="gva-menu-icon" :class="normalizeIconfontClass(routerInfo.meta.icon)" />
    </template>
    <template v-else>
      {{ isCollapse ? routerInfo.meta.title[0] : "" }}
    </template>
    <template #title>
      {{ routerInfo.meta.title }}
    </template>
  </el-menu-item>
</template>

<script setup>
import {computed, inject} from 'vue'
  import { useAppStore } from '@/pinia'
  import { storeToRefs } from 'pinia'
  import { normalizeIconfontClass } from '@/core/iconfontRegistry'
  const appStore = useAppStore()
  const { config } = storeToRefs(appStore)

  defineOptions({
    name: 'MenuItem'
  })

  defineProps({
    routerInfo: {
      default: function () {
        return null
      },
      type: Object
    }
  })

const isCollapse = inject('isCollapse', {
  default: false
})

  const sideHeight = computed(() => {
    return config.value.layout_side_item_height + 'px'
  })

</script>

<style lang="scss">
  .gva-menu-icon {
    display: inline-flex;
    flex-shrink: 0;
    align-items: center;
    justify-content: center;
    width: 18px;
    margin-right: 8px;
    font-size: 16px;
    line-height: 1;
  }

  .el-menu--collapse .gva-menu-icon {
    margin-right: 0;
  }
</style>
