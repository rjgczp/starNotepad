export const iconfontPrefix = 'iconfont'

export const iconfontIcons = [
  'icon-coffee',
  'icon-checklist',
  'icon-search',
  'icon-cloud',
  'icon-lock',
  'icon-moon',
  'icon-sun',
  'icon-zhiding',
  'icon-icon-test',
  'icon-icon-test1',
  'icon-icon-test2',
  'icon-alipay',
  'icon-aixin',
  'icon-bianji',
  'icon-anquan',
  'icon-bangzhu',
  'icon-buganxingqu',
  'icon-bofangjilu',
  'icon-chuangzuo',
  'icon-chenggong',
  'icon-ceshi',
  'icon-dianzan',
  'icon-dingwei',
  'icon-ditu',
  'icon-gengduo',
  'icon-faxian',
  'icon-fuzhi',
  'icon-huiyuan',
  'icon-jianshao',
  'icon-huati',
  'icon-guanzhu',
  'icon-mima',
  'icon-nan',
  'icon-nv',
  'icon-paihangbang',
  'icon-pengyouquan',
  'icon-saoyisao',
  'icon-rili',
  'icon-riqian',
  'icon-shandian',
  'icon-shezhi',
  'icon-shouji',
  'icon-tishi',
  'icon-wode',
  'icon-xiaoxi-zhihui',
  'icon-shouye-zhihui',
  'icon-yingyinqu',
  'icon-jianshenfang',
  'icon-shequhuodong',
  'icon-bar-chart',
  'icon-del',
  'icon-fullscreen-exit',
  'icon-a-addmodule',
  'icon-intersection',
  'icon-img',
  'icon-inbox',
  'icon-folder',
  'icon-repeat',
  'icon-intersectionbeifen',
  'icon-sign-out',
  'icon-virtual',
  'icon-data-statistics'
]

const fallbackIcon = 'icon-icon-test'

export const iconfontAliasMap = {
  aim: 'icon-dingwei',
  avatar: 'icon-wode',
  back: 'icon-repeat',
  bell: 'icon-tishi',
  box: 'icon-folder',
  calendar: 'icon-rili',
  cherry: 'icon-a-addmodule',
  cloudy: 'icon-cloud',
  cloud: 'icon-cloud',
  compass: 'icon-faxian',
  coordinate: 'icon-dingwei',
  cpu: 'icon-virtual',
  document: 'icon-inbox',
  files: 'icon-inbox',
  folder: 'icon-folder',
  house: 'icon-shouye-zhihui',
  info: 'icon-tishi',
  'info-filled': 'icon-tishi',
  key: 'icon-lock',
  list: 'icon-checklist',
  magic: 'icon-shandian',
  'magic-stick': 'icon-shandian',
  magnet: 'icon-intersection',
  menu: 'icon-checklist',
  message: 'icon-xiaoxi-zhihui',
  monitor: 'icon-data-statistics',
  notebook: 'icon-inbox',
  odometer: 'icon-data-statistics',
  operation: 'icon-shezhi',
  'partly-cloudy': 'icon-cloud',
  picture: 'icon-img',
  'picture-filled': 'icon-img',
  'pie-chart': 'icon-bar-chart',
  platform: 'icon-virtual',
  reading: 'icon-inbox',
  'reading-lamp': 'icon-sign-out',
  search: 'icon-search',
  setting: 'icon-shezhi',
  tickets: 'icon-checklist',
  upload: 'icon-cloud',
  'upload-filled': 'icon-cloud',
  user: 'icon-wode',
  view: 'icon-faxian',
  wallet: 'icon-huiyuan',
  warning: 'icon-tishi',
  'warning-filled': 'icon-tishi',
  scaleToOriginal: 'icon-fullscreen-exit',
  'scale-to-original': 'icon-fullscreen-exit'
}

const getStoredIconClass = (value) => {
  const parts = String(value || '').trim().split(/\s+/)
  return parts.find((item) => item.startsWith('icon-')) || ''
}

export const resolveIconfontName = (value) => {
  const storedIcon = getStoredIconClass(value)
  const raw = storedIcon || String(value || '').trim()
  if (!raw) return ''

  if (iconfontIcons.includes(raw)) return raw
  if (iconfontAliasMap[raw]) return iconfontAliasMap[raw]

  const normalized = raw.startsWith('icon-') ? raw : `icon-${raw}`
  if (iconfontIcons.includes(normalized)) return normalized

  return fallbackIcon
}

export const normalizeIconfontClass = (value) => {
  const iconName = resolveIconfontName(value)
  return iconName ? `${iconfontPrefix} ${iconName}` : ''
}

export const isIconfont = (value) => Boolean(resolveIconfontName(value))

export const iconfontOptions = iconfontIcons.map((name) => ({
  key: name,
  label: name
}))
