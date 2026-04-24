import 'dart:convert';

import 'package:flutter/material.dart';

import '../../tools/localData.dart';
import '../db/db_instance.dart';
import '../network/api_client.dart';

class ThemeColorItem {
  final int id;
  final String name;
  final Color color;

  const ThemeColorItem({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': color.toARGB32(),
  };

  factory ThemeColorItem.fromJson(Map<String, dynamic> json) {
    return ThemeColorItem(
      id: json['id'] as int,
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }
}

class ThemeProvider extends ChangeNotifier {
  static const String _selectedColorKey = 'theme_selected_color';
  static const String _colorListKey = 'theme_color_list';
  static const String _colorOrderKey = 'theme_color_order_ids';
  static const String _colorHiddenKey = 'theme_color_hidden_ids';
  static const Color _defaultColor = Color(0xFF4E80EE);

  Color _primaryColor = _defaultColor;
  List<ThemeColorItem> _colors = [];
  Set<int> _hiddenColorIds = <int>{};
  bool _loading = false;

  Color get primaryColor => _primaryColor;
  List<ThemeColorItem> get colors =>
      _colors.where((item) => !_hiddenColorIds.contains(item.id)).toList();
  List<ThemeColorItem> get allColors =>
      List<ThemeColorItem>.unmodifiable(_colors);
  bool get loading => _loading;

  bool isColorVisible(int id) => !_hiddenColorIds.contains(id);

  /// Singleton
  static final ThemeProvider _instance = ThemeProvider._();
  factory ThemeProvider() => _instance;
  ThemeProvider._();

  /// Load saved color from local storage immediately (sync)
  Future<void> loadFromLocal() async {
    // Load selected color
    final savedHex = LocalData.getString(_selectedColorKey);
    if (savedHex.isNotEmpty) {
      final parsed = _parseHexColor(savedHex);
      if (parsed != null) _primaryColor = parsed;
    }

    // Load colors from local database
    await _loadColorsFromDatabase(savedHex);
  }

  /// Load colors from local database
  Future<void> _loadColorsFromDatabase(String savedHex) async {
    try {
      final db = DbInstance.db;
      final colorItems = await db.getAllColors();

      _colors =
          colorItems.map((item) {
            final color = _parseHexColor(item.color) ?? _defaultColor;
            return ThemeColorItem(id: item.id, name: item.colors, color: color);
          }).toList();
      _applyDisplayPreferencesToColors();

      // If no colors in database, try to load from cache
      if (_colors.isEmpty) {
        final listJson = LocalData.getString(_colorListKey);
        if (listJson.isNotEmpty) {
          try {
            final decoded = jsonDecode(listJson) as List;
            _colors =
                decoded
                    .map(
                      (e) =>
                          ThemeColorItem.fromJson(Map<String, dynamic>.from(e)),
                    )
                    .toList();
            _applyDisplayPreferencesToColors();
          } catch (_) {}
        }
      }

      // If no color was previously selected, use the first one
      if (_colors.isNotEmpty && savedHex.isEmpty) {
        final visible = colors;
        _primaryColor =
            (visible.isNotEmpty ? visible.first : _colors.first).color;
        await _saveSelectedColor(_primaryColor);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeProvider] Error loading from database: $e');
      // Fallback to cached list
      final listJson = LocalData.getString(_colorListKey);
      if (listJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(listJson) as List;
          _colors =
              decoded
                  .map(
                    (e) =>
                        ThemeColorItem.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList();
          _applyDisplayPreferencesToColors();
          notifyListeners();
        } catch (_) {}
      }
    }
  }

  /// Fetch color list from API and cache locally
  Future<void> syncFromApi() async {
    _loading = true;
    notifyListeners();

    try {
      final client = ApiClient();
      final res = await client.request<dynamic>(
        '/api/uscolor/list',
        method: 'GET',
      );

      final body = res.data;
      if (body is! Map) return;
      final map = Map<String, dynamic>.from(body);
      final data = map['data'];
      if (data is! List) return;

      final items = <ThemeColorItem>[];
      for (final item in data) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final id = m['ID'] as int? ?? 0;
        final name = m['colors']?.toString() ?? '';
        final colorStr = m['color']?.toString() ?? '';
        final color = _parseHexColor(colorStr);
        if (color != null) {
          items.add(ThemeColorItem(id: id, name: name, color: color));
        }
      }

      if (items.isNotEmpty) {
        _colors = items;
        _applyDisplayPreferencesToColors();

        // Cache list
        final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
        await LocalData.setString(_colorListKey, encoded);

        // If no color was previously selected, use the first one
        final savedHex = LocalData.getString(_selectedColorKey);
        if (savedHex.isEmpty) {
          final visible = colors;
          _primaryColor =
              (visible.isNotEmpty ? visible.first : items.first).color;
          await _saveSelectedColor(_primaryColor);
        }
      }
    } catch (e) {
      debugPrint('[ThemeProvider] sync error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Change the primary color and persist
  Future<void> setColor(Color color) async {
    if (_primaryColor == color) return;
    _primaryColor = color;
    notifyListeners();
    await _saveSelectedColor(color);
  }

  Future<void> reorderColors(int oldIndex, int newIndex) async {
    if (_colors.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= _colors.length) return;
    if (newIndex < 0 || newIndex > _colors.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _colors.removeAt(oldIndex);
    _colors.insert(newIndex, item);
    _groupHiddenToBottomInPlace();

    await _saveColorOrder();
    notifyListeners();
  }

  Future<void> setColorVisibility(int id, bool visible) async {
    final currentIndex = _colors.indexWhere((item) => item.id == id);
    ThemeColorItem? movedItem;
    if (currentIndex >= 0) {
      movedItem = _colors.removeAt(currentIndex);
    }

    if (visible) {
      _hiddenColorIds.remove(id);
      if (movedItem != null) {
        final firstHiddenIndex = _colors.indexWhere(
          (item) => _hiddenColorIds.contains(item.id),
        );
        if (firstHiddenIndex == -1) {
          _colors.add(movedItem);
        } else {
          _colors.insert(firstHiddenIndex, movedItem);
        }
      }
    } else {
      _hiddenColorIds.add(id);
      if (movedItem != null) {
        _colors.add(movedItem);
      }
    }

    _groupHiddenToBottomInPlace();
    await _saveColorOrder();
    await _saveHiddenColorIds();
    notifyListeners();
  }

  void _applyDisplayPreferencesToColors() {
    _hiddenColorIds = _readHiddenColorIds();
    final order = _readColorOrder();
    if (order.isEmpty || _colors.length <= 1) return;

    final rank = <int, int>{};
    for (var i = 0; i < order.length; i++) {
      rank[order[i]] = i;
    }

    _colors.sort((a, b) {
      final aRank = rank[a.id];
      final bRank = rank[b.id];
      if (aRank != null && bRank != null) return aRank.compareTo(bRank);
      if (aRank != null) return -1;
      if (bRank != null) return 1;
      return 0;
    });
    _groupHiddenToBottomInPlace();
  }

  void _groupHiddenToBottomInPlace() {
    if (_colors.length <= 1) return;
    final visible = <ThemeColorItem>[];
    final hidden = <ThemeColorItem>[];
    for (final item in _colors) {
      if (_hiddenColorIds.contains(item.id)) {
        hidden.add(item);
      } else {
        visible.add(item);
      }
    }
    _colors = [...visible, ...hidden];
  }

  List<int> _readColorOrder() {
    final raw = LocalData.getString(_colorOrderKey).trim();
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  Set<int> _readHiddenColorIds() {
    final raw = LocalData.getString(_colorHiddenKey).trim();
    if (raw.isEmpty) return <int>{};
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toSet();
  }

  Future<void> _saveColorOrder() async {
    final ids = _colors.map((e) => e.id).toList();
    await LocalData.setString(_colorOrderKey, ids.join(','));
  }

  Future<void> _saveHiddenColorIds() async {
    final ids = _hiddenColorIds.toList()..sort();
    await LocalData.setString(_colorHiddenKey, ids.join(','));
  }

  Future<void> _saveSelectedColor(Color color) async {
    final hex =
        '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    await LocalData.setString(_selectedColorKey, hex);
  }

  static Color? _parseHexColor(String value) {
    var s = value.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('#')) s = s.substring(1);
    if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);
    final hex = s.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    if (hex.length == 8) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(v);
    }
    return null;
  }
}
