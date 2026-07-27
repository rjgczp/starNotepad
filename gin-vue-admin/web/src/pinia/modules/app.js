import { defineStore } from 'pinia'
import { setBodyPrimaryColor } from '@/utils/format'

const DEFAULT_PRIMARY_COLOR = '#4E80EE'

const defaultConfig = () => ({
  show_watermark: false,
  side_mode: 'normal',
  transition_type: 'fade-transform',
  showTabs: true,
  primaryColor: DEFAULT_PRIMARY_COLOR,
  darkMode: 'light',
  global_size: 'default',
  grey: false,
  weakness: false,
  keepAliveTabs: true,
  layout_side_width: 220,
  layout_side_collapsed_width: 64,
  layout_side_item_height: 44
})

const normalizeConfig = (config = {}) => ({
  ...defaultConfig(),
  ...Object.fromEntries(
    Object.entries(config || {}).filter(([, value]) => value !== undefined && value !== null)
  )
})

const normalizeColor = (color) => {
  if (typeof color !== 'string') return DEFAULT_PRIMARY_COLOR
  const value = color.trim()
  return /^#[0-9a-fA-F]{6}$/.test(value) ? value : DEFAULT_PRIMARY_COLOR
}

const getSystemDarkMode = () => {
  if (typeof window === 'undefined') return false
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches || false
}

export const useAppStore = defineStore('app', {
  state: () => ({
    config: normalizeConfig(),
    isDark: false,
    device: 'desktop',
    drawerSize: '800',
    operateMinWith: '240',
    cacheRoutes: []
  }),
  actions: {
    applyTheme() {
      this.config = normalizeConfig(this.config)
      this.config.primaryColor = normalizeColor(this.config.primaryColor)

      const darkMode = this.config.darkMode || 'light'
      const shouldUseDark = darkMode === 'auto' ? getSystemDarkMode() : darkMode === 'dark'
      this.isDark = shouldUseDark

      if (typeof document !== 'undefined') {
        document.documentElement.classList.toggle('dark', shouldUseDark)
        document.documentElement.classList.toggle('gva-grey-mode', Boolean(this.config.grey))
        document.documentElement.classList.toggle('gva-weakness-mode', Boolean(this.config.weakness))
        document.documentElement.classList.toggle('html-grey', Boolean(this.config.grey))
        document.documentElement.classList.toggle('html-weakenss', Boolean(this.config.weakness))
        setBodyPrimaryColor(this.config.primaryColor, shouldUseDark ? 'dark' : 'light')
      }
    },
    setConfig(config = {}) {
      this.config = normalizeConfig(config)
      this.applyTheme()
    },
    resetConfig() {
      this.config = defaultConfig()
      localStorage.setItem('originSetting', JSON.stringify(this.config))
      this.applyTheme()
    },
    toggleTheme(dark) {
      this.config.darkMode = dark ? 'dark' : 'light'
      this.applyTheme()
    },
    toggleDarkMode(mode) {
      this.config.darkMode = mode || 'light'
      this.applyTheme()
    },
    togglePrimaryColor(color) {
      this.config.primaryColor = normalizeColor(color)
      this.applyTheme()
    },
    toggleGlobalSize(size) {
      this.config.global_size = size || 'default'
    },
    toggleGrey(value) {
      this.config.grey = Boolean(value)
      this.applyTheme()
    },
    toggleWeakness(value) {
      this.config.weakness = Boolean(value)
      this.applyTheme()
    },
    toggleConfigWatermark(value) {
      this.config.show_watermark = Boolean(value)
    },
    toggleSideMode(mode) {
      this.config.side_mode = mode || 'normal'
    },
    toggleTabs(value) {
      this.config.showTabs = Boolean(value)
    },
    toggleTransition(type) {
      this.config.transition_type = type || 'fade-transform'
    },
    toggleDevice(device) {
      this.device = device
      if (device === 'mobile') {
        this.drawerSize = '100%'
        this.operateMinWith = '80'
      } else {
        this.drawerSize = '800'
        this.operateMinWith = '240'
      }
    }
  }
})
