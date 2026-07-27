import service from '@/utils/request'
export const getDuoCallAdmin = () => service({ url: '/duoCall/admin/list', method: 'get' })
export const saveDuoIdentity = (data) => service({ url: '/duoCall/admin/identity', method: 'post', data })
export const saveDuoStatus = (data) => service({ url: '/duoCall/admin/status', method: 'post', data })
export const deleteDuoStatus = (params) => service({ url: '/duoCall/admin/status', method: 'delete', params })
export const saveDuoAlbum = (data) => service({ url: '/duoCall/admin/album', method: 'post', data })
export const deleteDuoAlbum = (params) => service({ url: '/duoCall/admin/album', method: 'delete', params })
export const saveDuoAnniversary = (data) => service({ url: '/duoCall/admin/anniversary', method: 'post', data })
export const deleteDuoAnniversary = (params) => service({ url: '/duoCall/admin/anniversary', method: 'delete', params })
