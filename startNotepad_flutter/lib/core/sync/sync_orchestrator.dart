import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/db_instance.dart';
import '../network/api_client.dart';
import '../../features/note/data/note_api.dart';
import '../../tools/localData.dart';

class SyncOrchestrator {
  final AppDatabase _db = DbInstance.db;
  final NoteApi _api = NoteApi(ApiClient());

  /// Perform unified sync for all tables
  Future<void> syncAll() async {
    print('[SyncOrchestrator] Starting unified sync');

    // 1. Pull remote data
    final pullData = await _pullRemoteData();

    // 2. Process remote data for each table
    await _processRemoteNotes(pullData['notes']?['items'] ?? []);
    await _processRemoteCategories(pullData['categories']?['items'] ?? []);
    await _processRemoteColors(pullData['colors']?['items'] ?? []);

    // 3. Process sync queue and build push payload
    final pushPayload = await _buildPushPayload();

    // 4. Push local changes
    if (pushPayload.isNotEmpty) {
      await _pushLocalChanges(pushPayload);
    }

    print('[SyncOrchestrator] Unified sync completed');
  }

  /// Pull data from remote API
  Future<Map<String, dynamic>> _pullRemoteData() async {
    print('[SyncOrchestrator] Pulling remote data');

    // Get last sync timestamp to send to server
    final lastSyncAt = LocalData.getString('_lastServerSyncAt');
    final requestData =
        lastSyncAt.isNotEmpty ? {'lastSyncAt': lastSyncAt} : null;

    final response = await _api.syncPull(data: requestData);

    if (response.statusCode != 200) {
      throw Exception('Failed to pull data: ${response.statusCode}');
    }

    final body = _requireBodyMap(response.data);
    final code = body['code'];
    if (code != 200 && code != 0) {
      throw Exception(body['message']?.toString() ?? 'Pull failed');
    }

    final data = _requireBodyMap(body['data']);
    print('[SyncOrchestrator] Pull success');
    return data;
  }

  /// Process remote notes
  Future<void> _processRemoteNotes(List<dynamic> items) async {
    print('[SyncOrchestrator] Processing ${items.length} remote notes');

    for (final item in items) {
      final remoteId = _asInt(item['ID'] ?? item['id']);
      if (remoteId == null) continue;

      final deletedAt = _asDateTime(item['deletedAt']);
      final updatedAt = _asDateTime(item['updatedAt']);

      if (deletedAt != null) {
        // Remote item is deleted
        await _handleRemoteDeletedNote(remoteId);
      } else {
        // Remote item is active
        await _handleRemoteActiveNote(item, remoteId, updatedAt);
      }
    }
  }

  /// Handle remote deleted note
  Future<void> _handleRemoteDeletedNote(int remoteId) async {
    final local = await _db.findNoteByRemoteId(remoteId);
    if (local == null) return;

    // Check if local has newer changes
    if (local.updatedAtLocal.isAfter(
      local.updatedAtRemote ?? DateTime.fromMillisecondsSinceEpoch(0),
    )) {
      print(
        '[SyncOrchestrator] Conflict: note $remoteId deleted remotely but has local changes',
      );
      return;
    }

    // Mark as deleted locally
    await _db.markNoteDeleted(local.localId);
    print('[SyncOrchestrator] Marked note $remoteId as deleted locally');
  }

  /// Handle remote active note
  Future<void> _handleRemoteActiveNote(
    Map<String, dynamic> item,
    int remoteId,
    DateTime? updatedAt,
  ) async {
    final local = await _db.findNoteByRemoteId(remoteId);

    if (local == null) {
      // New remote note, create locally
      await _createLocalNoteFromRemote(item, remoteId);
      return;
    }

    // Compare timestamps for conflict resolution
    final localUpdatedAt = local.updatedAtRemote ?? local.updatedAtLocal;
    if (updatedAt != null && localUpdatedAt.isAfter(updatedAt)) {
      print('[SyncOrchestrator] Skipping note $remoteId: local is newer');
      return;
    }

    // Update local note
    await _updateLocalNoteFromRemote(item, local.localId);
  }

  /// Create local note from remote data
  Future<void> _createLocalNoteFromRemote(
    Map<String, dynamic> item,
    int remoteId,
  ) async {
    final note = NotesCompanion.insert(
      remoteId: Value(remoteId),
      uuid: Value(item['uuid']?.toString() ?? ''),
      title: Value(item['title']?.toString() ?? ''),
      content: Value(item['content']?.toString() ?? ''),
      updatedAt: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      categoryId: Value(_asInt(item['categoryID'])),
      color: Value(item['color']?.toString()),
      icon: Value(item['icon']?.toString()),
      isTop: Value(_asBool(item['isTop'])),
      isHighlight: Value(_asBool(item['isHighlight'])),
      isReminder: Value(_asBool(item['remind'])),
      recordedAt: Value(_asDateTime(item['recordedAt'])),
      updatedAtLocal: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      isDirty: const Value(false),
      isDeleted: const Value(false),
      syncState: const Value(SyncState.synced),
    );

    await _db.createLocalNote(note);
    print('[SyncOrchestrator] Created local note from remote $remoteId');
  }

  /// Update local note from remote data
  Future<void> _updateLocalNoteFromRemote(
    Map<String, dynamic> item,
    int localId,
  ) async {
    final note = NotesCompanion(
      title: Value(item['title']?.toString() ?? ''),
      content: Value(item['content']?.toString() ?? ''),
      updatedAt: Value(_asDateTime(item['updatedAt'])),
      categoryId: Value(_asInt(item['categoryID'])),
      color: Value(item['color']?.toString()),
      icon: Value(item['icon']?.toString()),
      isTop: Value(_asBool(item['isTop'])),
      isHighlight: Value(_asBool(item['isHighlight'])),
      isReminder: Value(_asBool(item['remind'])),
      recordedAt: Value(_asDateTime(item['recordedAt'])),
      updatedAtLocal: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      isDirty: const Value(false),
      syncState: const Value(SyncState.synced),
    );

    await _db.updateNoteByLocalId(localId, note);
    print('[SyncOrchestrator] Updated local note $localId from remote');
  }

  /// Process remote categories
  Future<void> _processRemoteCategories(List<dynamic> items) async {
    print('[SyncOrchestrator] Processing ${items.length} remote categories');

    for (final item in items) {
      final remoteId = _asInt(item['ID'] ?? item['id']);
      if (remoteId == null) continue;

      final deletedAt = _asDateTime(item['deletedAt']);
      final updatedAt = _asDateTime(item['updatedAt']);

      if (deletedAt != null) {
        await _handleRemoteDeletedCategory(remoteId);
      } else {
        await _handleRemoteActiveCategory(item, remoteId, updatedAt);
      }
    }
  }

  /// Handle remote deleted category
  Future<void> _handleRemoteDeletedCategory(int remoteId) async {
    final categories =
        await (_db.select(_db.categories)
          ..where((t) => t.remoteId.equals(remoteId))).get();

    if (categories.isEmpty) return;
    final local = categories.first;

    if (local.updatedAtLocal.isAfter(
      local.updatedAtRemote ?? DateTime.fromMillisecondsSinceEpoch(0),
    )) {
      print(
        '[SyncOrchestrator] Conflict: category $remoteId deleted remotely but has local changes',
      );
      return;
    }

    await (_db.delete(_db.categories)
      ..where((t) => t.localId.equals(local.localId))).go();
    print('[SyncOrchestrator] Deleted category $remoteId locally');
  }

  /// Handle remote active category
  Future<void> _handleRemoteActiveCategory(
    Map<String, dynamic> item,
    int remoteId,
    DateTime? updatedAt,
  ) async {
    final categories =
        await (_db.select(_db.categories)
          ..where((t) => t.remoteId.equals(remoteId))).get();

    if (categories.isEmpty) {
      await _createLocalCategoryFromRemote(item, remoteId);
      return;
    }

    final local = categories.first;
    final localUpdatedAt = local.updatedAtRemote ?? local.updatedAtLocal;
    if (updatedAt != null && localUpdatedAt.isAfter(updatedAt)) {
      print('[SyncOrchestrator] Skipping category $remoteId: local is newer');
      return;
    }

    await _updateLocalCategoryFromRemote(item, local.localId, local.userId);
  }

  /// Create local category from remote data
  Future<void> _createLocalCategoryFromRemote(
    Map<String, dynamic> item,
    int remoteId,
  ) async {
    final parsedUserId = _extractCategoryUserId(item, fallback: 1);
    final category = CategoriesCompanion.insert(
      remoteId: Value(remoteId),
      name: item['name']?.toString() ?? '',
      color: Value(item['color']?.toString()),
      icon: Value(item['icon']?.toString()),
      userId: Value(parsedUserId),
      updatedAtLocal: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      syncState: const Value(SyncState.synced),
    );

    await _db.into(_db.categories).insert(category);
    print('[SyncOrchestrator] Created local category from remote $remoteId');
  }

  /// Update local category from remote data
  Future<void> _updateLocalCategoryFromRemote(
    Map<String, dynamic> item,
    int localId,
    int currentUserId,
  ) async {
    final parsedUserId = _extractCategoryUserId(item, fallback: currentUserId);
    final category = CategoriesCompanion(
      name: Value(item['name']?.toString() ?? ''),
      color: Value(item['color']?.toString()),
      icon: Value(item['icon']?.toString()),
      userId: Value(parsedUserId),
      updatedAtLocal: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      syncState: const Value(SyncState.synced),
    );

    await (_db.update(_db.categories)
      ..where((t) => t.localId.equals(localId))).write(category);
    print('[SyncOrchestrator] Updated local category $localId from remote');
  }

  /// Process remote colors
  Future<void> _processRemoteColors(List<dynamic> items) async {
    print('[SyncOrchestrator] Processing ${items.length} remote colors');

    for (final item in items) {
      final remoteId = _asInt(item['ID'] ?? item['id']);
      if (remoteId == null) continue;

      final deletedAt = _asDateTime(item['deletedAt']);
      final updatedAt = _asDateTime(item['updatedAt']);

      if (deletedAt != null) {
        await _handleRemoteDeletedColor(remoteId);
      } else {
        await _handleRemoteActiveColor(item, remoteId, updatedAt);
      }
    }
  }

  /// Handle remote deleted color
  Future<void> _handleRemoteDeletedColor(int remoteId) async {
    final colors =
        await (_db.select(_db.colorItems)
          ..where((t) => t.remoteId.equals(remoteId))).get();

    if (colors.isEmpty) return;
    final local = colors.first;

    if (local.updatedAt.isAfter(
      local.updatedAtRemote ?? DateTime.fromMillisecondsSinceEpoch(0),
    )) {
      print(
        '[SyncOrchestrator] Conflict: color $remoteId deleted remotely but has local changes',
      );
      return;
    }

    await _db.deleteColor(local.id);
    print('[SyncOrchestrator] Deleted color $remoteId locally');
  }

  /// Handle remote active color
  Future<void> _handleRemoteActiveColor(
    Map<String, dynamic> item,
    int remoteId,
    DateTime? updatedAt,
  ) async {
    final colors =
        await (_db.select(_db.colorItems)
          ..where((t) => t.remoteId.equals(remoteId))).get();

    if (colors.isEmpty) {
      await _createLocalColorFromRemote(item, remoteId);
      return;
    }

    final local = colors.first;
    final localUpdatedAt = local.updatedAtRemote ?? local.updatedAt;
    if (updatedAt != null && localUpdatedAt.isAfter(updatedAt)) {
      print('[SyncOrchestrator] Skipping color $remoteId: local is newer');
      return;
    }

    await _updateLocalColorFromRemote(item, local.id);
  }

  /// Create local color from remote data
  Future<void> _createLocalColorFromRemote(
    Map<String, dynamic> item,
    int remoteId,
  ) async {
    final color = ColorItemsCompanion.insert(
      remoteId: Value(remoteId),
      colors: item['colors']?.toString() ?? '',
      color: item['color']?.toString() ?? '',
      createdAt: Value(_asDateTime(item['createdAt']) ?? DateTime.now()),
      updatedAt: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      syncState: const Value(SyncState.synced),
    );

    await _db.createColor(color);
    print('[SyncOrchestrator] Created local color from remote $remoteId');
  }

  /// Update local color from remote data
  Future<void> _updateLocalColorFromRemote(
    Map<String, dynamic> item,
    int localId,
  ) async {
    final color = ColorItemsCompanion(
      colors: Value(item['colors']?.toString() ?? ''),
      color: Value(item['color']?.toString() ?? ''),
      updatedAt: Value(_asDateTime(item['updatedAt']) ?? DateTime.now()),
      updatedAtRemote: Value(_asDateTime(item['updatedAt'])),
      syncState: const Value(SyncState.synced),
    );

    await _db.updateColor(localId, color);
    print('[SyncOrchestrator] Updated local color $localId from remote');
  }

  /// Build unified push payload from sync queue
  Future<Map<String, dynamic>> _buildPushPayload() async {
    print('[SyncOrchestrator] Building push payload');

    final payload = <String, dynamic>{
      'notes': <String, dynamic>{
        'upserts': <Map<String, dynamic>>[],
        'deletedIds': <int>[],
      },
      'categories': <String, dynamic>{
        'upserts': <Map<String, dynamic>>[],
        'deletedIds': <int>[],
      },
      'colors': <String, dynamic>{
        'upserts': <Map<String, dynamic>>[],
        'deletedIds': <int>[],
      },
    };

    // Get all pending sync queue items
    final queueItems =
        await (_db.select(_db.syncQueue)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

    // Group by entity type
    final notesQueue = queueItems.where((i) => i.entityType == 'note').toList();
    final categoriesQueue =
        queueItems.where((i) => i.entityType == 'category').toList();
    final colorsQueue =
        queueItems.where((i) => i.entityType == 'color').toList();

    // Process notes
    for (final item in notesQueue) {
      if (item.op == 'delete') {
        final note = await _db.findNoteByLocalId(item.entityLocalId);
        if (note?.remoteId != null) {
          payload['notes']['deletedIds'].add(note!.remoteId!);
        }
      } else {
        final note = await _db.findNoteByLocalId(item.entityLocalId);
        if (note != null && note.remoteId == null && item.op == 'create') {
          // New note without remoteId - skip for now, will use create API
          print(
            '[SyncOrchestrator] Skipping new note ${note.localId} in sync push',
          );
          continue;
        }
        final noteData = _buildNoteUpsertData(note!);
        if (noteData != null) {
          payload['notes']['upserts'].add(noteData);
        }
      }
    }

    // Process categories
    for (final item in categoriesQueue) {
      if (item.op == 'delete') {
        final categories =
            await (_db.select(_db.categories)
              ..where((t) => t.localId.equals(item.entityLocalId))).get();
        if (categories.isNotEmpty && categories.first.remoteId != null) {
          payload['categories']['deletedIds'].add(categories.first.remoteId!);
        }
      } else {
        final categories =
            await (_db.select(_db.categories)
              ..where((t) => t.localId.equals(item.entityLocalId))).get();
        if (categories.isNotEmpty) {
          final categoryData = _buildCategoryUpsertData(categories.first);
          if (categoryData != null) {
            payload['categories']['upserts'].add(categoryData);
          }
        }
      }
    }

    // Process colors
    for (final item in colorsQueue) {
      if (item.op == 'delete') {
        final colors =
            await (_db.select(_db.colorItems)
              ..where((t) => t.id.equals(item.entityLocalId))).get();
        if (colors.isNotEmpty && colors.first.remoteId != null) {
          payload['colors']['deletedIds'].add(colors.first.remoteId!);
        }
      } else {
        final colors =
            await (_db.select(_db.colorItems)
              ..where((t) => t.id.equals(item.entityLocalId))).get();
        if (colors.isNotEmpty) {
          final colorData = _buildColorUpsertData(colors.first);
          if (colorData != null) {
            payload['colors']['upserts'].add(colorData);
          }
        }
      }
    }

    print('[SyncOrchestrator] Built push payload: ${jsonEncode(payload)}');
    return payload;
  }

  /// Build note upsert data
  Map<String, dynamic>? _buildNoteUpsertData(Note note) {
    if (note.remoteId == null) return null;

    return <String, dynamic>{
      'ID': note.remoteId,
      'title': note.title,
      'content': note.content,
      'categoryID': note.categoryId,
      'isTop': note.isTop,
      'remind': note.isReminder,
      'color': note.color,
      'icon': note.icon,
      'isHighlight': note.isHighlight,
      'recordedAt': note.recordedAt?.toIso8601String(),
      'createdAt': note.updatedAtLocal.toIso8601String(),
      'updatedAt': note.updatedAtLocal.toIso8601String(),
    };
  }

  /// Build category upsert data
  Map<String, dynamic>? _buildCategoryUpsertData(Category category) {
    return <String, dynamic>{
      if (category.remoteId != null) 'ID': category.remoteId,
      'name': category.name,
      'color': category.color,
      'icon': category.icon,
      'createdAt': category.updatedAtLocal.toIso8601String(),
      'updatedAt': category.updatedAtLocal.toIso8601String(),
    };
  }

  /// Build color upsert data
  Map<String, dynamic>? _buildColorUpsertData(ColorItem color) {
    return <String, dynamic>{
      if (color.remoteId != null) 'ID': color.remoteId,
      'colors': color.colors,
      'color': color.color,
      'createdAt': color.createdAt.toIso8601String(),
      'updatedAt': color.updatedAt.toIso8601String(),
    };
  }

  /// Push local changes to remote
  Future<void> _pushLocalChanges(Map<String, dynamic> payload) async {
    print('[SyncOrchestrator] Pushing local changes');

    final response = await _api.syncPush(data: payload);

    if (response.statusCode != 200) {
      throw Exception('Failed to push data: ${response.statusCode}');
    }

    final body = _requireBodyMap(response.data);
    final code = body['code'];
    if (code != 200 && code != 0) {
      throw Exception(body['message']?.toString() ?? 'Push failed');
    }

    // Clear processed sync queue items
    await _clearSyncQueue();

    // Update sync timestamp from push response if available
    if (body['data'] != null && body['data']['serverSyncAt'] != null) {
      await LocalData.setString(
        '_lastServerSyncAt',
        body['data']['serverSyncAt'],
      );
    }

    print('[SyncOrchestrator] Push success');
  }

  /// Clear processed sync queue items
  Future<void> _clearSyncQueue() async {
    await _db.delete(_db.syncQueue).go();
    print('[SyncOrchestrator] Cleared sync queue');
  }

  // Helper methods
  Map<String, dynamic> _requireBodyMap(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }
    return data;
  }

  int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  bool _asBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool _extractSystemFlag(Map<String, dynamic> map) {
    return _asBool(map['isSystem']) ||
        _asBool(map['system']) ||
        _asBool(map['isDefault']) ||
        _asBool(map['default']);
  }

  int _extractCategoryUserId(
    Map<String, dynamic> map, {
    required int fallback,
  }) {
    final uid = _asInt(map['userID'] ?? map['userId']);
    if (uid != null) return uid;
    return _extractSystemFlag(map) ? 0 : fallback;
  }
}
