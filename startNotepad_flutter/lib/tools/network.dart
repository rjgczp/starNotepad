import 'package:dio/dio.dart';

class Network {
  // static const String _defaultBaseUrl = 'http://10.0.2.2:8888'; // 模拟器测试
  static const String _defaultBaseUrl = 'http://127.0.0.1:8888'; // 真机测试
  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: _defaultBaseUrl,
  );

  static String get baseUrl => _baseUrl;

  // 单例配置
  static final Dio _dio = Dio(
    BaseOptions(
      // baseUrl can be overridden by --dart-define=BASE_URL=...
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  static Future<Response> request(
    String url,
    String method, {
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final requestHeaders = <String, dynamic>{};
      requestHeaders.addAll(headers ?? {});

      return await _dio.request(
        url,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: requestHeaders),
      );
    } on DioException {
      rethrow;
    }
  }
}
