import 'package:flutter/material.dart';
import 'iconfont_icons.dart';
import 'iconfont_registry.dart';

/// 统一的 Iconfont 图标组件
/// 仅支持 iconfont 图标系统
class IconfontWidget extends StatelessWidget {
  final String iconName;
  final double size;
  final Color? color;

  const IconfontWidget({
    Key? key,
    required this.iconName,
    this.size = 16.0,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 空值检查
    if (iconName.isEmpty) {
      return Icon(
        Icons.help_outline,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      );
    }

    // 使用 IconfontIcons 的 fromCssClass 方法获取图标
    final iconData = IconfontIcons.fromCssClass(iconName);

    if (iconData != null) {
      return Icon(
        iconData,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      );
    }

    // 如果是 "apps" 这样的特殊值，返回对应图标
    if (iconName == 'apps') {
      return Icon(
        Icons.apps,
        size: size,
        color: color ?? Theme.of(context).iconTheme.color,
      );
    }

    // 都没找到，返回默认图标
    return Icon(
      Icons.help_outline,
      size: size,
      color: color ?? Theme.of(context).iconTheme.color,
    );
  }
}

/// 图标解析工具类
class IconfontParser {
  /// 解析图标字符串，返回 IconData
  /// 支持：
  /// - "iconfont icon-xxx"
  /// - "icon-xxx"
  /// - "gvaIcon-xxx"
  static IconData? parse(String? iconStr) {
    if (iconStr == null || iconStr.isEmpty) return null;

    // 移除前缀
    String cleanIconStr = iconStr;
    if (iconStr.startsWith('iconfont ')) {
      cleanIconStr = iconStr.replaceFirst('iconfont ', '').trim();
    }

    // 使用 IconfontIcons 的 fromCssClass 方法
    return IconfontIcons.fromCssClass(cleanIconStr);
  }

  /// 批量解析图标
  static List<String> parseList(List<String>? iconStrings) {
    if (iconStrings == null || iconStrings.isEmpty) return [];

    return iconStrings.where((icon) {
      return IconfontRegistry.isValidIcon(icon) ||
          IconfontRegistry.isValidIcon('iconfont $icon');
    }).toList();
  }
}
