import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

class HistoryDayApi {
  final ApiClient _client;

  HistoryDayApi(this._client);

  Future<Response<dynamic>> getHistoryDayToday() {
    return _client.request<dynamic>(
      '/api/hd/getHistoryDayToday',
      method: 'GET',
    );
  }

  Future<Response<dynamic>> getHistoryDayFuture() {
    return _client.request<dynamic>(
      '/api/hd/getHistoryDayFuture',
      method: 'GET',
    );
  }
}
