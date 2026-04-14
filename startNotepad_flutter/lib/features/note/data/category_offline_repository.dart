import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_instance.dart';
import '../../../tools/localData.dart';
import 'category_api.dart';

class CategoryOfflineRepository {
  CategoryOfflineRepository(this._api);

  static const String _categoryOrderKey = 'category_order_ids';
  static const String _categoryDisabledKey = 'category_disabled_ids';

  final CategoryApi _api;
  final AppDatabase _db = DbInstance.db;

  Future<void> createCategory({
    required String name,
    required String color,
    required String icon,
  }) async {
    final res = await _api.create(name: name, color: color, icon: icon);
    final body = _requireBodyMap(res.data);
    final code = body['code'];
    if (code != 0 && code != 200) {
      throw Exception(body['message']?.toString() ?? '创建分类失败');
    }
    await loadAll();
  }

  Future<void> updateCategory({
    required int id,
    required String name,
    required String color,
    required String icon,
  }) async {
    final res = await _api.update(id: id, name: name, color: color, icon: icon);
    final body = _requireBodyMap(res.data);
    final code = body['code'];
    if (code != 0 && code != 200) {
      throw Exception(body['message']?.toString() ?? '更新分类失败');
    }
    await loadAll();
  }

  Future<void> deleteCategory({required int id}) async {
    final res = await _api.delete(id: id);
    final body = _requireBodyMap(res.data);
    final code = body['code'];
    if (code != 0 && code != 200) {
      throw Exception(body['message']?.toString() ?? '删除分类失败');
    }
    final currentOrder = _readOrderIds()..remove(id);
    await _saveOrderIds(currentOrder);
    await loadAll();
  }

  Future<void> saveCategoryOrder(List<int> ids) {
    return _saveOrderIds(ids);
  }

  Future<void> setCategoryEnabled(int id, bool enabled) async {
    final ids = _readDisabledIds();
    if (enabled) {
      ids.remove(id);
    } else if (!ids.contains(id)) {
      ids.add(id);
    }
    await _saveDisabledIds(ids);
  }

  bool isCategoryEnabled(int id) {
    return !_readDisabledIds().contains(id);
  }

  Future<List<Map<String, dynamic>>> loadAll() async {
    final localRows = await _db.getActiveCategories();
    final localMapped = _sortBySavedOrder(_toMapList(localRows));

    try {
      final res = await _api.list();
      final body = _requireBodyMap(res.data);
      final code = body['code'];
      if (code != 0 && code != 200) {
        return localMapped;
      }

      final list = body['data'];
      if (list is! List) {
        return localMapped;
      }

      final rows = <CategoriesCompanion>[];
      for (final item in list) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final remoteId = _asInt(m['ID'] ?? m['id']);
        if (remoteId == null) continue;

        rows.add(
          CategoriesCompanion.insert(
            remoteId: Value(remoteId),
            name: m['name']?.toString() ?? '',
            color: Value(m['color']?.toString()),
            icon: Value(m['icon']?.toString()),
            updatedAtLocal: Value(DateTime.now()),
            syncState: const Value(SyncState.synced),
          ),
        );
      }

      if (rows.isNotEmpty) {
        await _db.replaceCategories(rows);
      }

      final refreshed = await _db.getActiveCategories();
      final mapped = _sortBySavedOrder(
        _mergeRemoteFlags(_toMapList(refreshed), list),
      );
      await _ensureOrderContainsAll(mapped);
      return mapped;
    } catch (_) {
      return localMapped;
    }
  }

  List<Map<String, dynamic>> _toMapList(List<Category> rows) {
    return rows
        .map(
          (c) => <String, dynamic>{
            'ID': c.remoteId ?? c.localId,
            'name': c.name,
            'color': c.color,
            'icon': c.icon,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> _mergeRemoteFlags(
    List<Map<String, dynamic>> localList,
    List<dynamic> remoteList,
  ) {
    final remoteFlags = <int, Map<String, dynamic>>{};
    for (final item in remoteList) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final id = _asInt(m['ID'] ?? m['id']);
      if (id == null) continue;
      remoteFlags[id] = <String, dynamic>{'isSystem': _extractSystemFlag(m)};
    }

    return localList.map((item) {
      final id = _asInt(item['ID']);
      final merged = Map<String, dynamic>.from(item);
      if (id != null && remoteFlags.containsKey(id)) {
        merged.addAll(remoteFlags[id]!);
      }
      return merged;
    }).toList();
  }

  bool _extractSystemFlag(Map<String, dynamic> map) {
    final userId = _asInt(map['userID'] ?? map['userId']);
    if (userId == 0) return true;

    return _asBool(map['isSystem']) ||
        _asBool(map['system']) ||
        _asBool(map['isDefault']) ||
        _asBool(map['default']);
  }

  List<Map<String, dynamic>> _sortBySavedOrder(
    List<Map<String, dynamic>> list,
  ) {
    final order = _readOrderIds();
    if (order.isEmpty) return list;

    final indexMap = <int, int>{};
    for (var i = 0; i < order.length; i++) {
      indexMap[order[i]] = i;
    }

    final sorted = List<Map<String, dynamic>>.from(list);
    sorted.sort((a, b) {
      final aId = _asInt(a['ID']) ?? -1;
      final bId = _asInt(b['ID']) ?? -1;
      final aIndex = indexMap[aId];
      final bIndex = indexMap[bId];
      if (aIndex == null && bIndex == null) {
        return (a['name']?.toString() ?? '').compareTo(
          b['name']?.toString() ?? '',
        );
      }
      if (aIndex == null) return 1;
      if (bIndex == null) return -1;
      return aIndex.compareTo(bIndex);
    });
    return sorted;
  }

  Future<void> _ensureOrderContainsAll(List<Map<String, dynamic>> list) async {
    final current = _readOrderIds();
    final ids = list.map((e) => _asInt(e['ID'])).whereType<int>().toList();
    var changed = false;
    for (final id in ids) {
      if (!current.contains(id)) {
        current.add(id);
        changed = true;
      }
    }
    current.removeWhere((id) => !ids.contains(id));
    if (changed || current.length != ids.length) {
      await _saveOrderIds(current);
    }
  }

  List<int> _readOrderIds() {
    final raw = LocalData.getString(_categoryOrderKey).trim();
    if (raw.isEmpty) return <int>[];
    return raw.split(',').map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> _saveOrderIds(List<int> ids) {
    return LocalData.setString(_categoryOrderKey, ids.join(','));
  }

  List<int> _readDisabledIds() {
    final raw = LocalData.getString(_categoryDisabledKey).trim();
    if (raw.isEmpty) return <int>[];
    return raw.split(',').map((e) => int.tryParse(e)).whereType<int>().toList();
  }

  Future<void> _saveDisabledIds(List<int> ids) {
    return LocalData.setString(_categoryDisabledKey, ids.join(','));
  }

  Map<String, dynamic> _requireBodyMap(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    return <String, dynamic>{};
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
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }
}
