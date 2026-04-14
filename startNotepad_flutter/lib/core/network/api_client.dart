import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import '../../tools/localData.dart';
import '../../tools/network.dart';

class ApiClient {
  static String get baseUrl => Network.baseUrl;

  static const String tokenKey = 'token';

  final Dio _dio;

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: Network.baseUrl,
              connectTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              validateStatus: (status) => status != null && status < 500,
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = LocalData.getString(tokenKey);
          if (token.isNotEmpty) {
            options.headers['x-token'] = token;
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response<T>> request<T>(
    String path, {
    required String method,
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? receiveTimeout,
  }) async {
    try {
      return await _dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          headers: headers,
          receiveTimeout: receiveTimeout,
        ),
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      throw NetworkException(
        e.message ?? 'Network error',
        statusCode: statusCode,
        cause: e,
      );
    }
  }

  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}
