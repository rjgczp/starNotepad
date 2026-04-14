import '../../../core/network/api_client.dart';
import 'package:dio/dio.dart';

class NoteStatisticsApi {
  final ApiClient _client;

  NoteStatisticsApi(this._client);

  /// 获取日记统计数据
  /// 返回每个日期对应的笔记图标列表
  Future<Response<dynamic>> getStatistics({
    String? startDate,
    String? endDate,
  }) {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['startDate'] = startDate;
    }
    if (endDate != null) {
      queryParams['endDate'] = endDate;
    }

    return _client.request<dynamic>(
      '/api/unote/statistics',
      method: 'GET',
      queryParameters: queryParams,
    );
  }
}
