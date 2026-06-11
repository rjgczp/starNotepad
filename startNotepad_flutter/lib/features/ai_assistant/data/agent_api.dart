import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';

/// AI Agent 接口客户端：把用户一句话指令 + 笔记上下文发给后端，
/// 后端返回 { reply, actions } 结构化结果。
class AgentApi {
  final ApiClient _client;

  AgentApi(this._client);

  Future<Response<dynamic>> chat({
    required String instruction,
    required List<Map<String, dynamic>> notes,
  }) {
    return _client.request<dynamic>(
      '/api/unote/agent',
      method: 'POST',
      data: <String, dynamic>{'instruction': instruction, 'notes': notes},
      headers: const <String, dynamic>{'Content-Type': 'application/json'},
      receiveTimeout: const Duration(seconds: 40),
    );
  }
}
