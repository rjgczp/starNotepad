import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class CategoryApi {
  final ApiClient _client;

  CategoryApi(this._client);

  /// 创建分类
  Future<Response<dynamic>> create({
    required String name,
    required String color,
    required String icon,
  }) {
    return _client.request<dynamic>(
      '/api/uncategory/create',
      method: 'POST',
      data: <String, dynamic>{
        'name': name,
        'color': color,
        'icon': icon,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  /// 获取分类列表（系统 + 本人）
  Future<Response<dynamic>> list() {
    return _client.request<dynamic>(
      '/api/uncategory/list',
      method: 'GET',
    );
  }

  /// 更新分类（仅本人，系统默认不可改）
  Future<Response<dynamic>> update({
    required int id,
    required String name,
    required String color,
    required String icon,
  }) {
    return _client.request<dynamic>(
      '/api/uncategory/update',
      method: 'PUT', 
      data: <String, dynamic>{
        'id': id,
        'name': name,
        'color': color,
        'icon': icon,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  /// 删除分类（仅本人，系统默认不可删）
  Future<Response<dynamic>> delete({required int id}) {
    return _client.request<dynamic>(
      '/api/uncategory/delete',
      method: 'DELETE',
      queryParameters: <String, dynamic>{'id': id},
    );
  }
}
