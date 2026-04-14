<template>
  <div class="color-picker-wrapper">
    <div class="color-grid">
      <div
        v-for="item in presetColors"
        :key="item.color"
        class="color-item"
        :class="{ active: modelValue === item.color }"
        :title="item.name"
        @click="selectColor(item.color)"
      >
        <span
          class="color-swatch"
          :style="{ backgroundColor: item.color }"
        >
          <el-icon v-if="modelValue === item.color" class="check-icon"><Check /></el-icon>
        </span>
        <span class="color-name">{{ item.name }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Check } from '@element-plus/icons-vue'

defineOptions({
  name: 'ColorPicker'
})

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:modelValue'])

const presetColors = [
  { color: '#4E80EE', name: '默认蓝' },
  { color: '#8bb5d1', name: '晨雾蓝' },
  { color: '#a8c8a8', name: '薄荷绿' },
  { color: '#d4a5a5', name: '玫瑰粉' },
  { color: '#c8a8d8', name: '薰衣草' },
  { color: '#f0c674', name: '暖阳黄' },
  { color: '#b8b8b8', name: '月光银' },
  { color: '#d8a8a8', name: '珊瑚橙' },
  { color: '#a8d8d8', name: '海雾青' },
  { color: '#c8c8a8', name: '橄榄绿' },
  { color: '#d8c8a8', name: '奶茶棕' },
  { color: '#a8a8d8', name: '梦幻紫' },
  { color: '#c8d8a8', name: '抹茶绿' }
]

const selectColor = (color) => {
  emit('update:modelValue', color)
}
</script>

<style scoped>
.color-picker-wrapper {
  width: 100%;
}

.color-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 8px;
}

.color-item {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 6px 8px;
  border: 2px solid #e5e7eb;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.15s ease;
}

.color-item:hover {
  border-color: #d1d5db;
  transform: translateY(-1px);
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.08);
}

.color-item.active {
  border-color: var(--el-color-primary);
  background-color: var(--el-color-primary-light-9);
}

.color-swatch {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 24px;
  height: 24px;
  border-radius: 6px;
  border: 1px solid rgba(0, 0, 0, 0.1);
  flex-shrink: 0;
}

.check-icon {
  color: #fff;
  font-size: 14px;
  text-shadow: 0 1px 2px rgba(0, 0, 0, 0.3);
}

.color-name {
  font-size: 12px;
  color: #374151;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
</style>
