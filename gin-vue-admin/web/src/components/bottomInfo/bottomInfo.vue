<template>
  <div class="flex items-center justify-center py-2 text-sm text-slate-700 dark:text-slate-500">
    <slot />
  </div>
</template>

<script setup>
  defineOptions({
    name: 'BottomInfo'
  })
</script>
