import 'package:drift/drift.dart';
import 'dart:convert';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_instance.dart';
import '../../../tools/localData.dart';
import 'note_api.dart';

class PageResult {
  final List<Map<String, dynamic>> notes;
  final int total;

  PageResult({required this.notes, required this.total});
}

class NoteOfflineRepository {
  NoteOfflineRepository(this._api);

  static const String _noteLastServerSyncAtKey = 'note_last_server_sync_at';

  final NoteApi _api;
  final AppDatabase _db = DbInstance.db;

  Future<int> createLocalFirst({
    required String title,
    required String content,
    bool isTop = false,
    int? categoryId,
    String? color,
    String? icon,
    bool isHighlight = false,
    bool isReminder = false,
    DateTime? recordedAt,
  }) async {
    final now = DateTime.now();
    final uuid = _newUuid(now);
    final localId = await _db.createLocalNote(
      NotesCompanion.insert(
        uuid: Value(uuid),
        title: Value(title),
        content: Value(content),
        updatedAt: Value(now),
        isDirty: const Value(true),
        isDeleted: const Value(false),
        categoryId: Value(categoryId),
        color: Value(color),
        icon: Value(icon),
        isTop: Value(isTop),
        isHighlight: Value(isHighlight),
        isReminder: Value(isReminder),
        recordedAt: Value(recordedAt),
        updatedAtLocal: Value(now),
        syncState: const Value(SyncState.pendingCreate),
      ),
    );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'note',
        entityLocalId: localId,
        op: 'create',
        payload: Value(
          jsonEncode(<String, dynamic>{
            'title': title,
            'content': content,
            'isTop': isTop,
            'categoryID': categoryId,
            'color': color,
            'icon': icon,
            'isHighlight': isHighlight,
            'isReminder': isReminder,
            'recordedAt': recordedAt?.toIso8601String(),
          }),
        ),
      ),
    );

    return localId;
  }

  Future<void> updateLocalFirst({required Map<String, dynamic> note}) async {
    final localId =
        _asInt(note['localId']) ??
        await _resolveLocalIdFromAnyId(note['id'] ?? note['ID']);
    if (localId == null) return;

    final now = DateTime.now();
    await _db.updateNoteByLocalId(
      localId,
      NotesCompanion(
        title: Value(note['title']?.toString() ?? ''),
        content: Value(note['content']?.toString() ?? ''),
        updatedAt: Value(now),
        isDirty: const Value(true),
        isDeleted: const Value(false),
        categoryId: Value(_asInt(note['categoryID'] ?? note['categoryId'])),
        color: Value(note['color']?.toString()),
        icon: Value(note['icon']?.toString()),
        isTop: Value(_asBool(note['isTop'])),
        isHighlight: Value(_asBool(note['isHighlight'])),
        isReminder: Value(_asBool(note['isReminder'])),
        recordedAt: Value(_asDateTime(note['recordedAt'])),
        updatedAtLocal: Value(now),
        syncState: const Value(SyncState.pendingUpdate),
      ),
    );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'note',
        entityLocalId: localId,
        op: 'update',
        payload: Value(jsonEncode(note)),
      ),
    );
  }

  Future<void> deleteLocalFirst({required dynamic id}) async {
    final localId = await _resolveLocalIdFromAnyId(id);
    if (localId == null) return;
    await _db.markNoteDeleted(localId);
  }

  Future<void> syncSilently() async {
    print('[NoteSync] syncSilently start');
    final pullRes = await _api.syncPull();
    print(
      '[NoteSync] pull raw status=${pullRes.statusCode} dataType=${pullRes.data.runtimeType}',
    );
    final pullBody = _requireBodyMap(pullRes.data);
    final pullCode = pullBody['code'];
    if (pullCode != 200 && pullCode != 0) {
      print(
        '[NoteSync] pull failed code=$pullCode message=${pullBody['message']}',
      );
      throw Exception(pullBody['message']?.toString() ?? '同步拉取失败');
    }

    final data = _requireBodyMap(pullBody['data']);
    final pulledItems = _extractPullItems(data);
    final deletedIds = <int>[];
    final activeItems = <Map<String, dynamic>>[];
    for (final item in pulledItems) {
      final remoteId = _asInt(item['ID'] ?? item['id']);
      if (remoteId == null) continue;
      if (_asDateTime(item['deletedAt'] ?? item['DeletedAt']) != null) {
        deletedIds.add(remoteId);
      } else {
        activeItems.add(item);
      }
    }
    print('[NoteSync] pull success deletedIds=${deletedIds.length}');
    if (deletedIds.isNotEmpty) {
      await _db.deleteNotesByRemoteIds(deletedIds);
    }

    final upserts = activeItems;
    print('[NoteSync] pull success upserts=${upserts.length}');
    final remoteById = <int, Map<String, dynamic>>{};
    for (final raw in upserts) {
      final remoteId = _asInt(raw['ID'] ?? raw['id']);
      if (remoteId == null) continue;
      remoteById[remoteId] = raw;
    }

    final allLocalNotes = await _db.getAllNotes();
    print('[NoteSync] local snapshot total=${allLocalNotes.length}');
    final pushPlan = await _buildSyncPlan(
      localNotes: allLocalNotes,
      remoteById: remoteById,
    );
    print(
      '[NoteSync] resolved plan upserts=${pushPlan.upserts.length} deletedIds=${pushPlan.deletedIds.length} '
      'remoteWinners=${pushPlan.remoteWinners.length} pendingDeleteLocalIds=${pushPlan.pendingDeleteLocalIds.length}',
    );

    for (final raw in pushPlan.remoteWinners) {
      final remoteId = _asInt(raw['ID'] ?? raw['id']);
      if (remoteId == null) continue;
      print('[NoteSync] apply remote winner remoteId=$remoteId');
      await _mergeRemoteRow(raw, remoteId);
    }

    if (pushPlan.upserts.isNotEmpty || pushPlan.deletedIds.isNotEmpty) {
      print(
        '[NoteSync] pushing upserts=${pushPlan.upserts.length} deletedIds=${pushPlan.deletedIds.length}',
      );
      print('[NoteSync] push payload upserts=${jsonEncode(pushPlan.upserts)}');
      print(
        '[NoteSync] push payload deletedIds=${jsonEncode(pushPlan.deletedIds)}',
      );
      final pushRes = await _api.syncPush(
        upserts: pushPlan.upserts,
        deletedIds: pushPlan.deletedIds,
      );
      print(
        '[NoteSync] push raw status=${pushRes.statusCode} dataType=${pushRes.data.runtimeType}',
      );
      print('[NoteSync] push raw body=${pushRes.data}');
      final pushBody = _requireBodyMap(pushRes.data);
      final pushCode = pushBody['code'];
      if (pushCode != 200 && pushCode != 0) {
        print(
          '[NoteSync] push failed code=$pushCode message=${pushBody['message']}',
        );
        throw Exception(pushBody['message']?.toString() ?? '同步上传失败');
      }
      print('[NoteSync] push success');

      if (pushPlan.syncedUuids.isNotEmpty) {
        await _db.markNotesSyncedByUuid(pushPlan.syncedUuids);
        print('[NoteSync] marked synced uuids=${pushPlan.syncedUuids.length}');
      }

      for (final localId in pushPlan.pendingDeleteLocalIds) {
        await _db.deleteNote(localId);
        print('[NoteSync] deleted local tombstone localId=$localId');
      }
    } else {
      print('[NoteSync] nothing to push');
    }

    final serverSyncAt = _extractServerSyncAt(data);
    if (serverSyncAt != null) {
      await LocalData.setString(
        _noteLastServerSyncAtKey,
        serverSyncAt.toIso8601String(),
      );
      print('[NoteSync] serverSyncAt=${serverSyncAt.toIso8601String()}');
    }
    print('[NoteSync] syncSilently done');
  }

  Future<PageResult> loadPage({
    required int page,
    required int pageSize,
    int? categoryId,
  }) async {
    final local = await _db.getActiveNotes(categoryId: categoryId);
    final localMapped = _toPagedMap(local, page: page, pageSize: pageSize);
    return PageResult(notes: localMapped, total: local.length);
  }

  List<Map<String, dynamic>> _toPagedMap(
    List<Note> rows, {
    required int page,
    required int pageSize,
  }) {
    final start = (page - 1) * pageSize;
    if (start >= rows.length) return <Map<String, dynamic>>[];
    final end = (start + pageSize).clamp(0, rows.length);
    final pageRows = rows.sublist(start, end);

    return pageRows
        .map(
          (n) => <String, dynamic>{
            'id': n.remoteId ?? n.localId,
            'localId': n.localId,
            'remoteId': n.remoteId,
            'title': n.title,
            'content': n.content,
            'categoryID': n.categoryId,
            'color': n.color,
            'icon': n.icon,
            'isTop': n.isTop,
            'isHighlight': n.isHighlight,
            'isReminder': n.isReminder,
            'recordedAt': n.recordedAt?.toIso8601String(),
            'updatedAt':
                (n.updatedAtRemote ?? n.updatedAtLocal).toIso8601String(),
            'createdAt':
                (n.updatedAtRemote ?? n.updatedAtLocal).toIso8601String(),
          },
        )
        .toList();
  }

  Map<String, dynamic> _mapRemoteRow(Map<String, dynamic> raw) {
    final remoteId = _asInt(raw['ID'] ?? raw['id']);
    return <String, dynamic>{
      'id': remoteId,
      'remoteId': remoteId,
      'title': raw['title']?.toString() ?? '',
      'content': raw['content']?.toString() ?? '',
      'categoryID': _asInt(raw['categoryID'] ?? raw['categoryId']),
      'color': raw['color']?.toString(),
      'icon': raw['icon']?.toString(),
      'isTop': _asBool(raw['isTop']),
      'isHighlight': _asBool(raw['isHighlight']),
      'isReminder': _asBool(raw['isReminder']),
      'recordedAt': _asDateTime(raw['recordedAt'])?.toIso8601String(),
      'updatedAt':
          (_asDateTime(raw['updatedAt'] ?? raw['UpdatedAt']) ?? DateTime.now())
              .toIso8601String(),
      'createdAt':
          (_asDateTime(raw['createdAt'] ?? raw['CreatedAt']) ?? DateTime.now())
              .toIso8601String(),
    };
  }

  Future<int?> _resolveLocalIdFromAnyId(dynamic id) async {
    final candidate = _asInt(id);
    if (candidate == null) return null;
    final byRemote = await _db.findNoteByRemoteId(candidate);
    if (byRemote != null) return byRemote.localId;
    return candidate;
  }

  Map<String, dynamic> _requireBodyMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final list = map['list'] ?? map['records'] ?? map['items'] ?? map['data'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _extractPullItems(Map<String, dynamic> data) {
    final explicitItems = data['items'];
    if (explicitItems is List) {
      return explicitItems
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    final upserts = data['upserts'];
    if (upserts is List) {
      return upserts
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return _extractList(data);
  }

  NotesCompanion _toSyncedCompanion(Map<String, dynamic> raw, int remoteId) {
    final updatedAt =
        _asDateTime(raw['updatedAt'] ?? raw['UpdatedAt']) ?? DateTime.now();
    return NotesCompanion(
      uuid: Value(raw['uuid']?.toString()),
      remoteId: Value(remoteId),
      title: Value(raw['title']?.toString() ?? ''),
      content: Value(raw['content']?.toString() ?? ''),
      updatedAt: Value(updatedAt),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      categoryId: Value(_asInt(raw['categoryID'] ?? raw['categoryId'])),
      color: Value(raw['color']?.toString()),
      icon: Value(raw['icon']?.toString()),
      isTop: Value(_asBool(raw['isTop'])),
      isHighlight: Value(_asBool(raw['isHighlight'])),
      isReminder: Value(_asBool(raw['isReminder'] ?? raw['remind'])),
      recordedAt: Value(_asDateTime(raw['recordedAt'])),
      updatedAtLocal: Value(updatedAt),
      updatedAtRemote: Value(updatedAt),
      deletedAt: const Value(null),
      syncState: const Value(SyncState.synced),
    );
  }

  Future<void> _mergeRemoteRow(Map<String, dynamic> raw, int remoteId) async {
    final synced = _toSyncedCompanion(raw, remoteId);
    final existingByRemoteId = await _db.findNoteByRemoteId(remoteId);
    if (existingByRemoteId != null) {
      await _db.updateNoteByLocalId(existingByRemoteId.localId, synced);
      return;
    }

    final matchedDraft = await _findMatchingLocalDraft(raw);
    if (matchedDraft != null) {
      await _db.updateNoteByLocalId(matchedDraft.localId, synced);
      return;
    }

    await _db.upsertNote(synced);
  }

  Future<Note?> _findMatchingLocalDraft(Map<String, dynamic> raw) async {
    final allNotes = await _db.getAllNotes();
    final remoteTitle = raw['title']?.toString().trim() ?? '';
    final remoteContent = raw['content']?.toString().trim() ?? '';
    final remoteCategoryId = _asInt(raw['categoryID'] ?? raw['categoryId']);
    final remoteColor = raw['color']?.toString();
    final remoteIcon = raw['icon']?.toString();
    final remoteIsTop = _asBool(raw['isTop']);
    final remoteIsHighlight = _asBool(raw['isHighlight']);
    final remoteIsReminder = _asBool(raw['isReminder'] ?? raw['remind']);
    final remoteRecordedAt = _asDateTime(raw['recordedAt']);

    for (final note in allNotes) {
      if (note.remoteId != null || note.isDeleted) continue;

      final sameRecordedAt =
          note.recordedAt == null && remoteRecordedAt == null ||
          (note.recordedAt != null &&
              remoteRecordedAt != null &&
              note.recordedAt!.isAtSameMomentAs(remoteRecordedAt));

      if (note.title.trim() == remoteTitle &&
          note.content.trim() == remoteContent &&
          note.categoryId == remoteCategoryId &&
          (note.color ?? '') == (remoteColor ?? '') &&
          (note.icon ?? '') == (remoteIcon ?? '') &&
          note.isTop == remoteIsTop &&
          note.isHighlight == remoteIsHighlight &&
          note.isReminder == remoteIsReminder &&
          sameRecordedAt) {
        return note;
      }
    }

    return null;
  }

  Future<_ResolvedSyncPlan> _buildSyncPlan({
    required List<Note> localNotes,
    required Map<int, Map<String, dynamic>> remoteById,
  }) async {
    final upserts = <Map<String, dynamic>>[];
    final deletedIds = <int>[];
    final syncedUuids = <String>[];
    final pendingDeleteLocalIds = <int>[];
    final remoteWinners = <Map<String, dynamic>>[];

    final localByRemoteId = <int, Note>{};
    for (final note in localNotes) {
      if (note.remoteId != null) {
        localByRemoteId[note.remoteId!] = note;
      }
    }

    for (final entry in remoteById.entries) {
      final remoteId = entry.key;
      final remoteRaw = entry.value;
      final local = localByRemoteId[remoteId];

      if (local == null) {
        print(
          '[NoteSync] remote-only active note remoteId=$remoteId -> pull to local',
        );
        remoteWinners.add(remoteRaw);
        continue;
      }

      if (local.isDeleted) {
        print(
          '[NoteSync] local deleted note remoteId=$remoteId localId=${local.localId} -> schedule delete',
        );
        deletedIds.add(remoteId);
        pendingDeleteLocalIds.add(local.localId);
        continue;
      }

      final localUpdatedAt = local.updatedAtLocal;
      final remoteUpdatedAt =
          _asDateTime(remoteRaw['updatedAt'] ?? remoteRaw['UpdatedAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0);

      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        print(
          '[NoteSync] remote wins remoteId=$remoteId localUpdatedAt=${localUpdatedAt.toIso8601String()} '
          'remoteUpdatedAt=${remoteUpdatedAt.toIso8601String()}',
        );
        remoteWinners.add(remoteRaw);
        continue;
      }

      print(
        '[NoteSync] local wins remoteId=$remoteId localId=${local.localId} '
        'localUpdatedAt=${localUpdatedAt.toIso8601String()} remoteUpdatedAt=${remoteUpdatedAt.toIso8601String()}',
      );
      upserts.add(_buildUpsertItem(local));
      final uuid = local.uuid;
      if (uuid != null && uuid.isNotEmpty) {
        syncedUuids.add(uuid);
      }
    }

    for (final note in localNotes) {
      if (note.remoteId != null && remoteById.containsKey(note.remoteId)) {
        continue;
      }

      if (note.isDeleted) {
        if (note.remoteId != null) {
          if (!deletedIds.contains(note.remoteId)) {
            print(
              '[NoteSync] local deleted unmatched remoteId=${note.remoteId} -> schedule delete',
            );
            deletedIds.add(note.remoteId!);
          }
        }
        pendingDeleteLocalIds.add(note.localId);
        continue;
      }

      if (note.remoteId == null || note.isDirty) {
        print(
          '[NoteSync] local pending upload localId=${note.localId} remoteId=${note.remoteId} '
          'isDirty=${note.isDirty} title=${note.title}',
        );
        upserts.add(_buildUpsertItem(note));
        final uuid = note.uuid;
        if (uuid != null && uuid.isNotEmpty) {
          syncedUuids.add(uuid);
        }
      }
    }

    return _ResolvedSyncPlan(
      upserts: upserts,
      deletedIds: deletedIds,
      syncedUuids: syncedUuids,
      pendingDeleteLocalIds: pendingDeleteLocalIds.toSet().toList(),
      remoteWinners: remoteWinners,
    );
  }

  Map<String, dynamic> _buildUpsertItem(Note note) {
    return <String, dynamic>{
      if (note.remoteId != null) 'ID': note.remoteId,
      'title': note.title,
      'content': note.content,
      'isTop': note.isTop,
      'remind': note.isReminder,
      if (note.categoryId != null) 'categoryID': note.categoryId,
      if (note.color != null && note.color!.isNotEmpty) 'color': note.color,
      if (note.icon != null && note.icon!.isNotEmpty) 'icon': note.icon,
      'isHighlight': note.isHighlight,
      if (note.recordedAt != null)
        'recordedAt': note.recordedAt!.toIso8601String(),
    };
  }

  DateTime? _extractServerSyncAt(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    return _asDateTime(map['serverSyncAt']);
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.replaceAll(' ', 'T'));
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    return null;
  }

  String _newUuid(DateTime now) {
    return 'local-${now.microsecondsSinceEpoch}-${now.millisecondsSinceEpoch % 100000}';
  }
}

class _ResolvedSyncPlan {
  _ResolvedSyncPlan({
    required this.upserts,
    required this.deletedIds,
    required this.syncedUuids,
    required this.pendingDeleteLocalIds,
    required this.remoteWinners,
  });

  final List<Map<String, dynamic>> upserts;
  final List<int> deletedIds;
  final List<String> syncedUuids;
  final List<int> pendingDeleteLocalIds;
  final List<Map<String, dynamic>> remoteWinners;
}
