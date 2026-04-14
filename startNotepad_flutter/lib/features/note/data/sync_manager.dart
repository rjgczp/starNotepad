import '../../../core/db/app_database.dart';
import '../../../tools/localData.dart';

class SyncNotePayload {
  SyncNotePayload({
    required this.uuid,
    required this.content,
    required this.updatedAt,
    required this.isDeleted,
  });

  final String uuid;
  final String content;
  final DateTime updatedAt;
  final bool isDeleted;

  factory SyncNotePayload.fromLocal(Note note) {
    return SyncNotePayload(
      uuid:
          (note.uuid == null || note.uuid!.isEmpty)
              ? 'local-${note.localId}'
              : note.uuid!,
      content: note.content,
      updatedAt: note.updatedAt ?? note.updatedAtLocal,
      isDeleted: note.isDeleted,
    );
  }
}

/// 远端同步接口定义（按你的后端接口补实现）
abstract class SyncRemoteDataSource {
  Future<bool> isOnline();

  Future<void> pushDirtyNotes(List<SyncNotePayload> dirtyNotes);

  Future<List<SyncNotePayload>> pullChangedNotes({
    required DateTime updatedAfter,
  });
}

/// 同步管理器（离线优先 + 最后写入者胜出）
class SyncManager {
  SyncManager({required AppDatabase db, required SyncRemoteDataSource remote})
    : _db = db,
      _remote = remote;

  static const String _lastSyncTimeKey = 'note_last_sync_time_ms';

  final AppDatabase _db;
  final SyncRemoteDataSource _remote;

  DateTime get _lastSyncTime {
    final ms = LocalData.getInt(_lastSyncTimeKey);
    if (ms <= 0) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> _saveLastSyncTime(DateTime time) async {
    await LocalData.setInt(_lastSyncTimeKey, time.millisecondsSinceEpoch);
  }

  Future<void> syncIfOnline() async {
    if (!await _remote.isOnline()) return;

    // 1) 推送离线脏数据（is_dirty = 1）
    final dirtyRows = await _db.getDirtyNotes();
    final dirtyPayloads = dirtyRows.map(SyncNotePayload.fromLocal).toList();

    if (dirtyPayloads.isNotEmpty) {
      await _remote.pushDirtyNotes(dirtyPayloads);
      await _db.markNotesSyncedByUuid(
        dirtyPayloads.map((e) => e.uuid).toList(),
      );
    }

    // 2) 拉取服务端增量（updated_at > last_sync_time）
    final changed = await _remote.pullChangedNotes(updatedAfter: _lastSyncTime);

    // 3) 冲突处理：最后写入者胜出（比较 updated_at）
    for (final item in changed) {
      await _db.upsertRemoteNoteLww(
        uuid: item.uuid,
        content: item.content,
        updatedAt: item.updatedAt,
        isDeleted: item.isDeleted,
      );
    }

    await _saveLastSyncTime(DateTime.now());
  }
}
