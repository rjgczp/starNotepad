import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_instance.dart';
import '../../../core/network/api_client.dart';
import '../../note/data/category_api.dart';
import '../../note/data/category_offline_repository.dart';
import '../../note/data/note_api.dart';
import '../../note/data/note_offline_repository.dart';
import 'agent_api.dart';
import 'agent_models.dart';

/// 负责 AI Agent 的整体编排：
/// 收集笔记上下文 → 调用后端 → 解析动作 → 执行（走离线优先同步）/ 导出。
class AgentController {
  AgentController()
    : _agentApi = AgentApi(ApiClient()),
      _noteRepo = NoteOfflineRepository(NoteApi(ApiClient())),
      _categoryRepo = CategoryOfflineRepository(CategoryApi(ApiClient()));

  final AgentApi _agentApi;
  final NoteOfflineRepository _noteRepo;
  final CategoryOfflineRepository _categoryRepo;
  final AppDatabase _db = DbInstance.db;

  /// 收集本地笔记摘要作为上下文（限制条数与长度，避免 token 过大）
  Future<List<Map<String, dynamic>>> buildNoteContext({int limit = 30}) async {
    final notes = await _db.getActiveNotes();
    final context = <Map<String, dynamic>>[];
    for (final note in notes.take(limit)) {
      final content = note.content;
      context.add(<String, dynamic>{
        'id': note.remoteId ?? note.localId,
        'title': note.title,
        'content': content.length > 200 ? content.substring(0, 200) : content,
        'category': note.categoryId?.toString() ?? '',
      });
    }
    return context;
  }

  /// 发送一句话指令，返回 AI 回复与待执行动作
  Future<AgentMessage> send(String instruction) async {
    final notes = await buildNoteContext();
    final res = await _agentApi.chat(instruction: instruction, notes: notes);
    final body = _asMap(res.data);
    final code = body['code'];
    if (code != 200 && code != 0) {
      throw Exception(body['message']?.toString() ?? 'AI 服务调用失败');
    }

    final data = _asMap(body['data']);
    final reply = data['reply']?.toString() ?? '已为你处理。';
    final actionsRaw = data['actions'];
    final actions = <AgentAction>[];
    if (actionsRaw is List) {
      for (final item in actionsRaw) {
        if (item is Map) {
          actions.add(AgentAction.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return AgentMessage(
      role: AgentMessageRole.assistant,
      text: reply,
      actions: actions,
    );
  }

  /// 执行单个动作。导出类动作返回是否需要外部处理已在内部完成。
  Future<void> executeAction(AgentAction action) async {
    switch (action.type) {
      case AgentActionType.createNote:
        await _executeCreate(action);
        break;
      case AgentActionType.updateNote:
        await _executeUpdate(action);
        break;
      case AgentActionType.mergeNotes:
        await _executeMerge(action);
        break;
      case AgentActionType.categorize:
        await _executeCategorize(action);
        break;
      case AgentActionType.export:
        await _executeExport(action);
        break;
      case AgentActionType.unknown:
        throw Exception('暂不支持的操作类型');
    }
  }

  Future<void> _executeCreate(AgentAction action) async {
    final categoryId = await _resolveCategoryId(action.category);
    await _noteRepo.createLocalFirst(
      title: action.title ?? '未命名',
      content: action.content ?? '',
      categoryId: categoryId,
    );
    await _syncQuietly();
  }

  Future<void> _executeUpdate(AgentAction action) async {
    final id = action.noteId;
    if (id == null) throw Exception('缺少笔记 ID');
    await _noteRepo.updateLocalFirst(
      note: <String, dynamic>{
        'id': id,
        'title': action.title ?? '',
        'content': action.content ?? '',
      },
    );
    await _syncQuietly();
  }

  Future<void> _executeMerge(AgentAction action) async {
    // 合并：新建一条合并后的笔记，并把源笔记删除。
    await _noteRepo.createLocalFirst(
      title: action.title ?? '合并笔记',
      content: action.content ?? '',
    );
    for (final id in action.sourceIds) {
      await _noteRepo.deleteLocalFirst(id: id);
    }
    await _syncQuietly();
  }

  Future<void> _executeCategorize(AgentAction action) async {
    final id = action.noteId;
    if (id == null) throw Exception('缺少笔记 ID');
    final categoryId = await _resolveCategoryId(action.category);
    final note = await _findNoteMap(id);
    if (note == null) throw Exception('未找到笔记 #$id');
    note['categoryID'] = categoryId;
    await _noteRepo.updateLocalFirst(note: note);
    await _syncQuietly();
  }

  Future<void> _executeExport(AgentAction action) async {
    final content = action.content ?? '';
    final title = action.title ?? '星记事导出';
    final dir = await getTemporaryDirectory();
    final safeName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File('${dir.path}/$safeName.md');
    await file.writeAsString(content.isEmpty ? '# $title\n' : content);
    await Share.shareXFiles([XFile(file.path)], text: title);
  }

  /// 根据分类名解析出本地分类 ID（找不到则返回 null = 不分类）
  Future<int?> _resolveCategoryId(String? name) async {
    final target = (name ?? '').trim();
    if (target.isEmpty) return null;
    final categories = await _categoryRepo.loadAll();
    for (final c in categories) {
      if (c['name']?.toString().trim() == target) {
        return _asInt(c['ID']);
      }
    }
    return null;
  }

  Future<Map<String, dynamic>?> _findNoteMap(int id) async {
    final byRemote = await _db.findNoteByRemoteId(id);
    final note = byRemote ?? await _db.findNoteByLocalId(id);
    if (note == null) return null;
    return <String, dynamic>{
      'id': note.remoteId ?? note.localId,
      'localId': note.localId,
      'title': note.title,
      'content': note.content,
      'categoryID': note.categoryId,
      'color': note.color,
      'icon': note.icon,
      'isTop': note.isTop,
      'isHighlight': note.isHighlight,
      'isReminder': note.isReminder,
      'recordedAt': note.recordedAt?.toIso8601String(),
    };
  }

  Future<void> _syncQuietly() async {
    try {
      await _noteRepo.syncSilently();
    } catch (_) {
      // 同步失败不阻塞本地操作，下次自动重试
    }
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
