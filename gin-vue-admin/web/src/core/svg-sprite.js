import lock from '@/assets/icons/lock.svg?raw'
import server from '@/assets/icons/server.svg?raw'
import close from '@/assets/icons/close.svg?raw'
import customerGva from '@/assets/icons/customer-gva.svg?raw'
import warn from '@/assets/icons/warn.svg?raw'
import idea from '@/assets/icons/idea.svg?raw'
import aiGva from '@/assets/icons/ai-gva.svg?raw'

const icons = {
  lock,
  server,
  close,
  'customer-gva': customerGva,
  warn,
  idea,
  'ai-gva': aiGva
}

const symbols = Object.entries(icons).map(([id, source]) => source
  .replace(/<\?xml[^>]*>/gi, '')
  .replace(/<!doctype[^>]*>/gi, '')
  .replace(/<svg\b/i, `<symbol id="${id}"`)
  .replace(/<\/svg>/i, '</symbol>'))
  .join('')

const sprite = document.createElementNS('http://www.w3.org/2000/svg', 'svg')
sprite.setAttribute('aria-hidden', 'true')
sprite.style.cssText = 'position:absolute;width:0;height:0;overflow:hidden'
sprite.innerHTML = symbols
document.body.prepend(sprite)
