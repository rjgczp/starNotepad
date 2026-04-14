<template>
  <el-menu-item
    :index="routerInfo.name"
    :style="{
          height: sideHeight
        }"
  >
    <template v-if="routerInfo.meta.icon">
      <i
        v-if="isIconfont(routerInfo.meta.icon)"
        :class="normalizeIconfontClass(routerInfo.meta.icon)"
      />
      <el-icon v-else>
        <component :is="routerInfo.meta.icon" />
      </el-icon>
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
  import { iconfontPrefix } from '@/core/iconfontRegistry'
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

  const isIconfont = (val) => {
    if (!val) return false
    return typeof val === 'string' && (val.includes(iconfontPrefix) || val.startsWith('icon-'))
  }

  const normalizeIconfontClass = (val) => {
    if (!val) return ''
    const str = String(val).trim()
    if (!str) return ''

    if (str.includes(iconfontPrefix)) return str
    const iconClass = str.startsWith('icon-') ? str : `icon-${str}`
    return `${iconfontPrefix} ${iconClass}`
  }
</script>

<style lang="scss"></style>
