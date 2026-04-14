import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class NoteApi {
  final ApiClient _client;

  NoteApi(this._client);

  Future<Response<dynamic>> all({
    int page = 1,
    int pageSize = 10,
    int? categoryId,
  }) {
    final queryParams = <String, dynamic>{'page': page, 'pageSize': pageSize};
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }

    return _client.request<dynamic>(
      '/api/unote/all',
      method: 'GET',
      queryParameters: queryParams,
    );
  }

  Future<Response<dynamic>> calendar({required String date}) {
    return _client.request<dynamic>(
      '/api/unote/calendar',
      method: 'GET',
      queryParameters: <String, dynamic>{'date': date},
    );
  }

  Future<Response<dynamic>> create({
    required String title,
    required String content,
    bool isTop = false,
    int? categoryID,
    String? color,
    String? icon,
    bool isHighlight = false,
    String? recordedAt,
  }) {
    return _client.request<dynamic>(
      '/api/unote/create',
      method: 'POST',
      data: <String, dynamic>{
        'title': title,
        'content': content,
        'isTop': isTop,
        if (categoryID != null) 'categoryID': categoryID,
        if (color != null) 'color': color,
        if (icon != null) 'icon': icon,
        'isHighlight': isHighlight,
        if (recordedAt != null) 'recordedAt': recordedAt,
      },
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> update({required Map<String, dynamic> note}) {
    return _client.request<dynamic>(
      '/api/unote/update',
      method: 'PUT',
      data: note,
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
    );
  }

  Future<Response<dynamic>> polish({required String text}) {
    return _client.request<dynamic>(
      '/api/unote/polish',
      method: 'POST',
      data: <String, dynamic>{'text': text},
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
      receiveTimeout: const Duration(seconds: 25),
    );
  }

  Future<Response<dynamic>> syncPull({Map<String, dynamic>? data}) {
    return _client.request<dynamic>(
      '/api/unote/sync/pull',
      method: 'POST',
      data: data,
    );
  }

  Future<Response<dynamic>> syncPush({required Map<String, dynamic> data}) {
    return _client.request<dynamic>(
      '/api/unote/sync/push',
      method: 'POST',
      data: data,
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
      receiveTimeout: const Duration(seconds: 25),
    );
  }
}
