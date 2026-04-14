import 'dart:convert';

import 'package:flutter/material.dart';

import '../../tools/localData.dart';
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
  static const Color _defaultColor = Color(0xFF4E80EE);

  Color _primaryColor = _defaultColor;
  List<ThemeColorItem> _colors = [];
  bool _loading = false;

  Color get primaryColor => _primaryColor;
  List<ThemeColorItem> get colors => _colors;
  bool get loading => _loading;

  /// Singleton
  static final ThemeProvider _instance = ThemeProvider._();
  factory ThemeProvider() => _instance;
  ThemeProvider._();

  /// Load saved color from local storage immediately (sync)
  void loadFromLocal() {
    // Load selected color
    final savedHex = LocalData.getString(_selectedColorKey);
    if (savedHex.isNotEmpty) {
      final parsed = _parseHexColor(savedHex);
      if (parsed != null) _primaryColor = parsed;
    }

    // Load cached color list
    final listJson = LocalData.getString(_colorListKey);
    if (listJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(listJson) as List;
        _colors =
            decoded
                .map(
                  (e) => ThemeColorItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList();
      } catch (_) {}
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

        // Cache list
        final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
        await LocalData.setString(_colorListKey, encoded);

        // If no color was previously selected, use the first one
        final savedHex = LocalData.getString(_selectedColorKey);
        if (savedHex.isEmpty) {
          _primaryColor = items.first.color;
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
