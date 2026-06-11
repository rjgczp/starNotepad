// AI Agent 相关的数据模型：聊天消息、待执行动作。

enum AgentMessageRole { user, assistant, system }


/// 单条对话消息
class AgentMessage {
  AgentMessage({
    required this.role,
    required this.text,
    this.actions = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final AgentMessageRole role;
  String text;
  final List<AgentAction> actions;
  final DateTime createdAt;

  bool get isUser => role == AgentMessageRole.user;
}

/// Agent 动作类型
enum AgentActionType { createNote, updateNote, mergeNotes, categorize, export, unknown }

AgentActionType _parseActionType(String? raw) {
  switch ((raw ?? '').trim()) {
    case 'create_note':
      return AgentActionType.createNote;
    case 'update_note':
      return AgentActionType.updateNote;
    case 'merge_notes':
      return AgentActionType.mergeNotes;
    case 'categorize':
      return AgentActionType.categorize;
    case 'export':
      return AgentActionType.export;
    default:
      return AgentActionType.unknown;
  }
}

enum AgentActionStatus { pending, done, ignored, failed }

/// 待执行/已执行的单个动作
class AgentAction {
  AgentAction({required this.type, required this.raw});

  final AgentActionType type;
  final Map<String, dynamic> raw;

  AgentActionStatus status = AgentActionStatus.pending;
  String? errorMessage;

  factory AgentAction.fromJson(Map<String, dynamic> json) {
    return AgentAction(type: _parseActionType(json['type']?.toString()), raw: json);
  }

  String? get title => raw['title']?.toString();
  String? get content => raw['content']?.toString();
  String? get category => raw['category']?.toString();

  int? get noteId => _asInt(raw['id']);

  List<int> get sourceIds {
    final v = raw['sourceIds'];
    if (v is List) {
      return v.map((e) => _asInt(e)).whereType<int>().toList();
    }
    return const [];
  }

  List<int> get noteIds {
    final v = raw['noteIds'];
    if (v is List) {
      return v.map((e) => _asInt(e)).whereType<int>().toList();
    }
    return const [];
  }

  /// 给用户看的动作摘要标题
  String get summaryTitle {
    switch (type) {
      case AgentActionType.createNote:
        return '新建笔记';
      case AgentActionType.updateNote:
        return '更新笔记';
      case AgentActionType.mergeNotes:
        return '合并笔记';
      case AgentActionType.categorize:
        return '调整分类';
      case AgentActionType.export:
        return '导出笔记';
      case AgentActionType.unknown:
        return '未知操作';
    }
  }

  /// 给用户看的动作详情描述
  String get summaryDetail {
    switch (type) {
      case AgentActionType.createNote:
        final t = title ?? '';
        return t.isEmpty ? (content ?? '') : '$t\n${content ?? ''}'.trim();
      case AgentActionType.updateNote:
        return '#${noteId ?? '-'} → ${title ?? ''}\n${content ?? ''}'.trim();
      case AgentActionType.mergeNotes:
        return '合并 ${sourceIds.join('、')} 为「${title ?? ''}」';
      case AgentActionType.categorize:
        return '笔记 #${noteId ?? '-'} → 分类「${category ?? ''}」';
      case AgentActionType.export:
        final count = noteIds.isEmpty ? '全部' : '${noteIds.length} 条';
        return '导出 $count 笔记为 ${raw['format'] ?? 'markdown'}';
      case AgentActionType.unknown:
        return raw.toString();
    }
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
