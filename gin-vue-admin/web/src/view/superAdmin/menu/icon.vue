<template>
  <div class="w-full">
    <el-select
      v-model="value"
      clearable
      filterable
      placeholder="请选择"
      class="w-full"
    >
      <template #prefix>
        <span v-if="value" class="inline-flex items-center">
          <i :class="normalizeIconfontClass(value)" />
        </span>
      </template>
      <el-option
        v-for="item in iconOptions"
        :key="item.key"
        class="select__option_item"
        :label="item.key"
        :value="item.key"
      >
        <span class="gva-icon" style="padding: 3px 0 0">
          <i :class="normalizeIconfontClass(item.label)" />
        </span>
        <span style="text-align: left">{{ item.key }}</span>
      </el-option>
    </el-select>
  </div>
</template>

<script setup>
  import { computed } from 'vue'
  import { iconfontOptions, normalizeIconfontClass } from '@/core/iconfontRegistry'

  defineOptions({
    name: 'Icon'
  })

  const value = defineModel()

  const iconOptions = computed(() => iconfontOptions)
</script>

<style lang="scss">
  .gva-icon {
    color: rgb(132, 146, 166);
    font-size: 14px;
    margin-right: 10px;
  }

  .select__option_item {
    display: flex;
    align-items: center;
    justify-content: flex-start;
  }
</style>
