<template>
  <div class="flex flex-wrap items-center justify-center gap-x-4 gap-y-1 py-2 text-xs text-slate-500 dark:text-slate-500">
    <a
      href="https://beian.miit.gov.cn/"
      target="_blank"
      rel="noreferrer"
      class="transition hover:text-slate-800 dark:hover:text-slate-300"
    >
      {{ ICP_BEIAN_NO }}
    </a>
    <a
      href="https://beian.mps.gov.cn/"
      target="_blank"
      rel="noreferrer"
      class="inline-flex items-center gap-1 transition hover:text-slate-800 dark:hover:text-slate-300"
    >
      <img :src="GONGAN_ICON" alt="" class="h-3.5 w-3.5">
      <span>{{ GONGAN_BEIAN_NO }}</span>
    </a>
    <slot />
  </div>
</template>

<script setup>
  const ICP_BEIAN_NO = '晋ICP备2026005636号'
  const GONGAN_BEIAN_NO = '晋ICP备2026005636号'
  const GONGAN_ICON = '/beian/gongan.png'

  defineOptions({
    name: 'BottomInfo'
  })
</script>
