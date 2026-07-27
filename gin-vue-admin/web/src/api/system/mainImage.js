import service from '@/utils/request'

export const getMainImages = () => service({ url: '/mainImage/list', method: 'get' })
export const createMainImage = (data) => service({ url: '/mainImage/create', method: 'post', data })
export const updateMainImage = (data) => service({ url: '/mainImage/update', method: 'put', data })
export const deleteMainImage = (params) => service({ url: '/mainImage/delete', method: 'delete', params })
