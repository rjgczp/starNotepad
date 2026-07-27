<template>
  <div
    ref="footerRef"
    class="flex flex-wrap items-center justify-center gap-x-2 gap-y-1 py-2 text-xs text-slate-500 transition-opacity duration-200 dark:text-slate-500"
    :class="visible ? 'opacity-100' : 'pointer-events-none opacity-0'"
  >
    <span>Copyright © 2026 三月海 |</span>
    <a
      href="https://beian.miit.gov.cn/"
      target="_blank"
      rel="noreferrer"
      class="transition hover:text-slate-800 dark:hover:text-slate-300"
    >
      晋ICP备2026005636号-2
    </a>
    <slot />
  </div>
</template>

<script setup>
  import { onBeforeUnmount, onMounted, ref } from 'vue'

  defineOptions({
    name: 'BottomInfo'
  })

  const visible = ref(false)
  const footerRef = ref(null)
  let scrollTarget = null

  const getScrollableParent = (el) => {
    let parent = el?.parentElement
    while (parent && parent !== document.body) {
      const style = window.getComputedStyle(parent)
      if (/(auto|scroll)/.test(`${style.overflow}${style.overflowY}`)) {
        return parent
      }
      parent = parent.parentElement
    }
    return window
  }

  const updateVisible = () => {
    const scrollTop = scrollTarget === window
      ? window.scrollY || document.documentElement.scrollTop
      : scrollTarget?.scrollTop || 0
    visible.value = scrollTop > 80
  }

  onMounted(() => {
    scrollTarget = getScrollableParent(footerRef.value)
    if (scrollTarget === window) {
      window.addEventListener('scroll', updateVisible, { passive: true })
    } else {
      scrollTarget?.addEventListener('scroll', updateVisible, { passive: true })
    }
    updateVisible()
  })

  onBeforeUnmount(() => {
    if (scrollTarget === window) {
      window.removeEventListener('scroll', updateVisible)
    } else {
      scrollTarget?.removeEventListener('scroll', updateVisible)
    }
  })
</script>
