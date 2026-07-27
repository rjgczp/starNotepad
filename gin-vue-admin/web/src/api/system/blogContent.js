import service from '@/utils/request'

export const getBlogContent = () => service({ url: '/blogContent/list', method: 'get' })
export const createBlogItem = (kind, data) => service({ url: `/blogContent/${kind}`, method: 'post', data })
export const updateBlogItem = (kind, data) => service({ url: `/blogContent/${kind}`, method: 'put', data })
export const deleteBlogItem = (params) => service({ url: '/blogContent/delete', method: 'delete', params })
