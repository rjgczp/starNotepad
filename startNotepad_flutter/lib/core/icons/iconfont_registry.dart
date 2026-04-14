/// 图标注册表，与后端保持同步
class IconfontRegistry {
  // 禁止实例化
  IconfontRegistry._();

  /// iconfont 前缀
  static const String iconfontPrefix = 'iconfont';

  /// 在线图标列表（iconfont）
  /// 与后端 iconfontRegistry.js 保持一致
  static const List<String> iconfontIcons = [
    'icon-coffee',
    'icon-checklist',
    'icon-search',
    'icon-cloud',
    'icon-lock',
    'icon-moon',
    'icon-sun',
    'icon-zhiding',
    'icon-icon-test',
    'icon-icon-test1',
    'icon-icon-test2',
    'icon-alipay',
    'icon-aixin',
    'icon-bianji',
    'icon-anquan',
    'icon-bangzhu',
    'icon-buganxingqu',
    'icon-bofangjilu',
    'icon-chuangzuo',
    'icon-chenggong',
    'icon-ceshi',
    'icon-dianzan',
    'icon-dingwei',
    'icon-ditu',
    'icon-gengduo',
    'icon-faxian',
    'icon-fuzhi',
    'icon-huiyuan',
    'icon-jianshao',
    'icon-huati',
    'icon-guanzhu',
    'icon-mima',
    'icon-nan',
    'icon-nv',
    'icon-paihangbang',
    'icon-pengyouquan',
    'icon-saoyisao',
    'icon-rili',
    'icon-riqian',
    'icon-shandian',
    'icon-shezhi',
    'icon-shouji',
    'icon-tishi',
    'icon-wode',
    'icon-xiaoxi-zhihui',
    'icon-shouye-zhihui',
    'icon-yingyinqu',
    'icon-jianshenfang',
    'icon-shequhuodong',
    'icon-bar-chart',
    'icon-del',
    'icon-fullscreen-exit',
    'icon-a-addmodule',
    'icon-intersection',
    'icon-img',
    'icon-inbox',
    'icon-folder',
    'icon-repeat',
    'icon-intersectionbeifen',
    'icon-sign-out',
    'icon-virtual',
    'icon-data-statistics',
  ];

  /// 判断是否为有效的图标名称
  static bool isValidIcon(String iconName) {
    // 支持 "iconfont icon-xxx" 或 "icon-xxx" 格式
    String cleanName = iconName;
    if (iconName.startsWith('iconfont ')) {
      cleanName = iconName.replaceFirst('iconfont ', '').trim();
    }
    return iconfontIcons.contains(cleanName);
  }

  /// 获取图标类型
  static String getIconType(String iconName) {
    // 所有图标都是 iconfont 类型
    return 'iconfont';
  }

  /// 获取图标选项（用于下拉选择等）
  static List<Map<String, String>> get iconfontOptions {
    return iconfontIcons.map((name) => {'key': name, 'label': name}).toList();
  }
}
