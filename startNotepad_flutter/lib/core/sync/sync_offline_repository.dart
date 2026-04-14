import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../db/db_instance.dart';
import 'sync_orchestrator.dart';

/// Repository that handles offline storage and sync for notes, categories, and colors
class SyncOfflineRepository {
  final AppDatabase _db = DbInstance.db;
  final SyncOrchestrator _orchestrator = SyncOrchestrator();

  /// Perform unified sync for all tables
  Future<void> syncSilently() async {
    try {
      await _orchestrator.syncAll();
    } catch (e) {
      print('[SyncOfflineRepository] Sync failed: $e');
      rethrow;
    }
  }

  // Note-related methods

  /// Create a note locally first, then sync
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

  /// Update a note locally first, then sync
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

  /// Delete a note locally first, then sync
  Future<void> deleteLocalFirst({required dynamic id}) async {
    final localId = await _resolveLocalIdFromAnyId(id);
    if (localId == null) return;
    await _db.markNoteDeleted(localId);

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'note',
        entityLocalId: localId,
        op: 'delete',
      ),
    );
  }

  /// Get active notes (local-first)
  Future<PageResult> loadPage({
    required int page,
    required int pageSize,
    int? categoryId,
  }) async {
    final local = await _db.getActiveNotes(categoryId: categoryId);
    final localMapped = _toPagedMap(local, page: page, pageSize: pageSize);
    return PageResult(notes: localMapped, total: local.length);
  }

  /// Get all notes
  Future<List<Note>> getAllNotes() async {
    return await _db.getAllNotes();
  }

  /// Find note by local ID
  Future<Note?> findNoteByLocalId(int localId) async {
    final notes =
        await (_db.select(_db.notes)
          ..where((t) => t.localId.equals(localId))).get();
    return notes.isNotEmpty ? notes.first : null;
  }

  /// Find note by remote ID
  Future<Note?> findNoteByRemoteId(int remoteId) async {
    return await _db.findNoteByRemoteId(remoteId);
  }

  // Category-related methods

  /// Create a category locally first, then sync
  Future<int> createCategory({
    required String name,
    String? color,
    String? icon,
  }) async {
    final now = DateTime.now();
    final localId = await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            color: Value(color),
            icon: Value(icon),
            updatedAtLocal: Value(now),
            syncState: const Value(SyncState.pendingCreate),
          ),
        );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityLocalId: localId,
        op: 'create',
        payload: Value(
          jsonEncode(<String, dynamic>{
            'name': name,
            'color': color,
            'icon': icon,
          }),
        ),
      ),
    );

    return localId;
  }

  /// Update a category locally first, then sync
  Future<void> updateCategory({
    required int localId,
    required String name,
    String? color,
    String? icon,
  }) async {
    final now = DateTime.now();
    await (_db.update(_db.categories)
      ..where((t) => t.localId.equals(localId))).write(
      CategoriesCompanion(
        name: Value(name),
        color: Value(color),
        icon: Value(icon),
        updatedAtLocal: Value(now),
        syncState: const Value(SyncState.pendingUpdate),
      ),
    );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityLocalId: localId,
        op: 'update',
        payload: Value(
          jsonEncode(<String, dynamic>{
            'name': name,
            'color': color,
            'icon': icon,
          }),
        ),
      ),
    );
  }

  /// Delete a category locally first, then sync
  Future<void> deleteCategory(int localId) async {
    final categories =
        await (_db.select(_db.categories)
          ..where((t) => t.localId.equals(localId))).get();

    if (categories.isEmpty) return;
    final category = categories.first;

    if (category.remoteId != null) {
      // Has remote ID, mark for deletion
      await (_db.update(_db.categories)
        ..where((t) => t.localId.equals(localId))).write(
        CategoriesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAtLocal: Value(DateTime.now()),
          syncState: const Value(SyncState.pendingDelete),
        ),
      );
    } else {
      // Local only, delete immediately
      await (_db.delete(_db.categories)
        ..where((t) => t.localId.equals(localId))).go();
    }

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'category',
        entityLocalId: localId,
        op: 'delete',
      ),
    );
  }

  /// Get all categories
  Future<List<Category>> getAllCategories() async {
    return await (_db.select(_db.categories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  /// Find category by local ID
  Future<Category?> findCategoryByLocalId(int localId) async {
    final categories =
        await (_db.select(_db.categories)
          ..where((t) => t.localId.equals(localId))).get();
    return categories.isNotEmpty ? categories.first : null;
  }

  // Color-related methods

  /// Create a color locally first, then sync
  Future<int> createColor({
    required String colors,
    required String color,
  }) async {
    final now = DateTime.now();
    final localId = await _db.createColor(
      ColorItemsCompanion.insert(
        colors: colors,
        color: color,
        createdAt: Value(now),
        updatedAt: Value(now),
        syncState: const Value(SyncState.pendingCreate),
      ),
    );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'color',
        entityLocalId: localId,
        op: 'create',
        payload: Value(
          jsonEncode(<String, dynamic>{'colors': colors, 'color': color}),
        ),
      ),
    );

    return localId;
  }

  /// Update a color locally first, then sync
  Future<void> updateColor({
    required int localId,
    required String colors,
    required String color,
  }) async {
    final now = DateTime.now();
    await _db.updateColor(
      localId,
      ColorItemsCompanion(
        colors: Value(colors),
        color: Value(color),
        updatedAt: Value(now),
        syncState: const Value(SyncState.pendingUpdate),
      ),
    );

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'color',
        entityLocalId: localId,
        op: 'update',
        payload: Value(
          jsonEncode(<String, dynamic>{'colors': colors, 'color': color}),
        ),
      ),
    );
  }

  /// Delete a color locally first, then sync
  Future<void> deleteColor(int localId) async {
    final colors =
        await (_db.select(_db.colorItems)
          ..where((t) => t.id.equals(localId))).get();

    if (colors.isEmpty) return;
    final colorItem = colors.first;

    if (colorItem.remoteId != null) {
      // Has remote ID, mark for deletion
      await _db.updateColor(
        localId,
        ColorItemsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
          syncState: const Value(SyncState.pendingDelete),
        ),
      );
    } else {
      // Local only, delete immediately
      await _db.deleteColor(localId);
    }

    await _db.enqueueSync(
      SyncQueueCompanion.insert(
        entityType: 'color',
        entityLocalId: localId,
        op: 'delete',
      ),
    );
  }

  /// Get all colors
  Future<List<ColorItem>> getAllColors() async {
    return await _db.getAllColors();
  }

  /// Find color by local ID
  Future<ColorItem?> findColorByLocalId(int localId) async {
    return await _db.findColorById(localId);
  }

  /// Find color by name
  Future<ColorItem?> findColorByName(String name) async {
    return await _db.findColorByName(name);
  }

  /// Replace all colors (used for initial sync)
  Future<void> replaceColors(List<ColorItemsCompanion> rows) async {
    await _db.replaceColors(rows);
  }

  // Helper methods

  String _newUuid(DateTime now) {
    final timestamp = now.millisecondsSinceEpoch;
    final random = (timestamp % 900000 + 100000).toString();
    final uuid = 'local-$timestamp-$random';
    return uuid;
  }

  Future<int?> _resolveLocalIdFromAnyId(dynamic id) async {
    if (id == null) return null;
    final intId = int.tryParse(id.toString());
    if (intId == null) return null;

    // Try to find by local ID first
    final notes =
        await (_db.select(_db.notes)
          ..where((t) => t.localId.equals(intId))).get();
    if (notes.isNotEmpty) return intId;

    // Try to find by remote ID
    final remoteNote = await _db.findNoteByRemoteId(intId);
    return remoteNote?.localId;
  }

  List<Map<String, dynamic>> _toPagedMap(
    List<Note> notes, {
    required int page,
    required int pageSize,
  }) {
    final start = (page - 1) * pageSize;
    final end = (start + pageSize).clamp(0, notes.length);

    if (start >= notes.length) return [];

    return notes
        .sublist(start, end)
        .map(
          (note) => <String, dynamic>{
            'id': note.localId,
            'ID': note.remoteId,
            'uuid': note.uuid,
            'title': note.title,
            'content': note.content,
            'updatedAt': note.updatedAt?.toIso8601String(),
            'isDirty': note.isDirty,
            'isDeleted': note.isDeleted,
            'categoryId': note.categoryId,
            'color': note.color,
            'icon': note.icon,
            'isTop': note.isTop,
            'isHighlight': note.isHighlight,
            'isReminder': note.isReminder,
            'recordedAt': note.recordedAt?.toIso8601String(),
            'updatedAtLocal': note.updatedAtLocal.toIso8601String(),
            'updatedAtRemote': note.updatedAtRemote?.toIso8601String(),
            'deletedAt': note.deletedAt?.toIso8601String(),
            'syncState': note.syncState,
            'dirtyFields': note.dirtyFields,
          },
        )
        .toList();
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
}

/// Page result for pagination
class PageResult {
  final List<Map<String, dynamic>> notes;
  final int total;

  PageResult({required this.notes, required this.total});
}
