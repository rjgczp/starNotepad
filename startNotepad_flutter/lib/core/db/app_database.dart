import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class SyncState {
  static const int synced = 0;
  static const int pendingCreate = 1;
  static const int pendingUpdate = 2;
  static const int pendingDelete = 3;
  static const int conflict = 4;
}

class Notes extends Table {
  IntColumn get localId => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get uuid => text().named('uuid').nullable()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().named('updated_at').nullable()();
  BoolColumn get isDirty =>
      boolean().named('is_dirty').withDefault(const Constant(false))();
  BoolColumn get isDeleted =>
      boolean().named('is_deleted').withDefault(const Constant(false))();
  IntColumn get categoryId => integer().nullable()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  BoolColumn get isTop => boolean().withDefault(const Constant(false))();
  BoolColumn get isHighlight => boolean().withDefault(const Constant(false))();
  BoolColumn get isReminder => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recordedAt => dateTime().nullable()();
  DateTimeColumn get updatedAtLocal =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAtRemote => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncState =>
      integer().withDefault(const Constant(SyncState.synced))();
  TextColumn get dirtyFields => text().nullable()();
}

class Categories extends Table {
  IntColumn get localId => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get color => text().nullable()();
  TextColumn get icon => text().nullable()();
  IntColumn get userId => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAtLocal =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAtRemote => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncState =>
      integer().withDefault(const Constant(SyncState.synced))();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  IntColumn get entityLocalId => integer()();
  TextColumn get op => text()();
  TextColumn get payload => text().nullable()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ColorItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get colors => text()();
  TextColumn get color => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAtRemote => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  IntColumn get syncState =>
      integer().withDefault(const Constant(SyncState.synced))();
}

@DriftDatabase(tables: [Notes, Categories, SyncQueue, ColorItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // First time: add new sync columns
        // Use try-catch to handle cases where columns might already exist
        try {
          await m.addColumn(notes, notes.uuid);
        } catch (_) {
          // Column already exists, ignore
        }
        try {
          await m.addColumn(notes, notes.updatedAt);
        } catch (_) {
          // Column already exists, ignore
        }
        try {
          await m.addColumn(notes, notes.isDirty);
        } catch (_) {
          // Column already exists, ignore
        }
        try {
          await m.addColumn(notes, notes.isDeleted);
        } catch (_) {
          // Column already exists, ignore
        }
      }
      if (from < 3) {
        // Ensure updatedAt is nullable (fix previous non-constant default issue)
        // No-op: schema already nullable; just bump version to trigger rebuild.
      }
      if (from < 4) {
        // Add ColorItems table
        await m.createTable(colorItems);
      }
      if (from < 5) {
        // Add sync columns to ColorItems table
        try {
          await m.addColumn(colorItems, colorItems.remoteId);
        } catch (_) {}
        try {
          await m.addColumn(colorItems, colorItems.updatedAtRemote);
        } catch (_) {}
        try {
          await m.addColumn(colorItems, colorItems.deletedAt);
        } catch (_) {}
        try {
          await m.addColumn(colorItems, colorItems.syncState);
        } catch (_) {}
      }
      if (from < 6) {
        // Add userId column to Categories table
        try {
          await m.addColumn(categories, categories.userId);
        } catch (_) {}
      }
    },
  );

  Future<List<Note>> getActiveNotes({int? categoryId}) {
    final q =
        select(notes)
          ..where((t) => t.deletedAt.isNull() & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    if (categoryId != null) {
      q.where((t) => t.categoryId.equals(categoryId));
    }

    return q.get();
  }

  Future<void> upsertNote(NotesCompanion note) async {
    // 先查找是否已存在相同 remoteId 或 uuid 的笔记
    Note? existing;

    if (note.remoteId.value != null) {
      existing = await findNoteByRemoteId(note.remoteId.value!);
    } else if (note.uuid.value != null) {
      existing =
          await (select(notes)
            ..where((t) => t.uuid.equals(note.uuid.value!))).getSingleOrNull();
    }

    if (existing != null) {
      // 如果存在，更新现有记录
      await updateNoteByLocalId(existing.localId, note);
    } else {
      // 如果不存在，创建新记录
      await createLocalNote(note);
    }
  }

  Future<int> createLocalNote(NotesCompanion note) {
    return into(notes).insert(note);
  }

  Future<Note?> findNoteByRemoteId(int remoteId) {
    return (select(notes)
      ..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();
  }

  Future<Note?> findNoteByLocalId(int localId) {
    return (select(notes)
      ..where((t) => t.localId.equals(localId))).getSingleOrNull();
  }

  Future<void> updateNoteByLocalId(int localId, NotesCompanion patch) async {
    await (update(notes)..where((t) => t.localId.equals(localId))).write(patch);
  }

  Future<void> markNoteDeleted(int localId) async {
    final now = DateTime.now();
    await (update(notes)..where((t) => t.localId.equals(localId))).write(
      NotesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        updatedAtLocal: Value(now),
        isDeleted: const Value(true),
        isDirty: const Value(true),
        syncState: const Value(SyncState.pendingDelete),
      ),
    );
  }

  /// 清理重复的笔记数据
  Future<int> cleanupDuplicateNotes() async {
    // 获取所有有 remoteId 的笔记，按 remoteId 分组
    final allNotes =
        await (select(notes)..where(
          (t) => t.remoteId.isBiggerThanValue(0) & t.isDeleted.equals(false),
        )).get();

    // 按 remoteId 分组
    final Map<int, List<Note>> grouped = {};
    for (final note in allNotes) {
      if (note.remoteId != null) {
        final rid = note.remoteId!;
        if (!grouped.containsKey(rid)) {
          grouped[rid] = [];
        }
        grouped[rid]!.add(note);
      }
    }

    int deletedCount = 0;

    // 对每个 remoteId 组，只保留最新的一个
    for (final entry in grouped.entries) {
      final notes = entry.value;
      if (notes.length > 1) {
        // 按更新时间排序，保留最新的
        notes.sort((a, b) {
          final aTime = a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

        // 删除除第一个外的所有重复记录
        for (int i = 1; i < notes.length; i++) {
          await deleteNote(notes[i].localId);
          deletedCount++;
        }
      }
    }

    return deletedCount;
  }

  /// 完全删除笔记（物理删除）
  Future<void> deleteNote(int localId) async {
    await (delete(notes)..where((t) => t.localId.equals(localId))).go();
  }

  Future<List<Note>> getDirtyNotes() {
    return (select(notes)
          ..where((t) => t.isDirty.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)]))
        .get();
  }

  Future<List<Note>> getAllNotes() {
    return select(notes).get();
  }

  Future<List<Note>> getNotesUpdatedAfter(DateTime lastSyncTime) {
    return (select(notes)
      ..where((t) => t.updatedAt.isBiggerThanValue(lastSyncTime))).get();
  }

  Future<Note?> findNoteByUuid(String uuid) {
    return (select(notes)..where((t) => t.uuid.equals(uuid))).getSingleOrNull();
  }

  Future<void> markNotesSyncedByUuid(List<String> uuids) async {
    if (uuids.isEmpty) return;
    await (update(notes)..where((t) => t.uuid.isIn(uuids))).write(
      NotesCompanion(
        isDirty: const Value(false),
        syncState: const Value(SyncState.synced),
        updatedAtRemote: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteNotesByRemoteIds(List<int> remoteIds) async {
    if (remoteIds.isEmpty) return;
    await (delete(notes)..where((t) => t.remoteId.isIn(remoteIds))).go();
  }

  Future<void> upsertRemoteNoteLww({
    required String uuid,
    required String content,
    required DateTime updatedAt,
    required bool isDeleted,
  }) async {
    final local = await findNoteByUuid(uuid);
    final localUpdatedAt = local?.updatedAt ?? local?.updatedAtLocal;
    if (localUpdatedAt != null && localUpdatedAt.isAfter(updatedAt)) {
      return;
    }

    final patch = NotesCompanion(
      uuid: Value(uuid),
      content: Value(content),
      updatedAt: Value(updatedAt),
      updatedAtLocal: Value(updatedAt),
      updatedAtRemote: Value(updatedAt),
      isDeleted: Value(isDeleted),
      isDirty: const Value(false),
      syncState: const Value(SyncState.synced),
      deletedAt: Value(isDeleted ? updatedAt : null),
    );

    if (local == null) {
      await createLocalNote(
        patch.copyWith(
          title: Value(
            content.length > 16 ? content.substring(0, 16) : content,
          ),
        ),
      );
      return;
    }

    await updateNoteByLocalId(local.localId, patch);
  }

  Future<List<Category>> getActiveCategories() {
    return (select(categories)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> replaceCategories(List<CategoriesCompanion> rows) async {
    await transaction(() async {
      await delete(categories).go();
      if (rows.isNotEmpty) {
        await batch((b) => b.insertAll(categories, rows));
      }
    });
  }

  Future<int> enqueueSync(SyncQueueCompanion entry) {
    return into(syncQueue).insert(entry);
  }

  // Color related methods
  Future<List<ColorItem>> getAllColors() {
    return (select(colorItems)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.colors)]))
        .get();
  }

  Future<ColorItem?> findColorById(int id) {
    return (select(colorItems)
      ..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<ColorItem?> findColorByName(String name) {
    return (select(colorItems)
      ..where((t) => t.colors.equals(name))).getSingleOrNull();
  }

  Future<int> createColor(ColorItemsCompanion color) {
    return into(colorItems).insert(color);
  }

  Future<void> updateColor(int id, ColorItemsCompanion color) async {
    final now = DateTime.now();
    final updateData = color.copyWith(updatedAt: Value(now));
    await (update(colorItems)..where((t) => t.id.equals(id))).write(updateData);
  }

  Future<void> deleteColor(int id) async {
    await (delete(colorItems)..where((t) => t.id.equals(id))).go();
  }

  Future<void> replaceColors(List<ColorItemsCompanion> rows) async {
    await transaction(() async {
      await delete(colorItems).go();
      if (rows.isNotEmpty) {
        await batch((b) => b.insertAll(colorItems, rows));
      }
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'start_notepad.db'));
    return NativeDatabase.createInBackground(file);
  });
}
