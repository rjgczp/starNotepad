import 'package:flutter/material.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/core/theme/theme_provider.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_repository_impl.dart';
import 'package:startnotepad_flutter/features/auth/data/auth_api.dart';
import 'package:startnotepad_flutter/features/ai_assistant/presentation/ai_assistant_page.dart';
import 'package:startnotepad_flutter/features/echo/presentation/echo_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_list_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/category_manage_page.dart';
import 'package:startnotepad_flutter/tools/localData.dart';
import '../begin/login.dart';
import '../features/note/data/category_api.dart';
import '../features/note/data/category_offline_repository.dart';
import '../features/note/data/note_api.dart';
import '../features/note/data/note_offline_repository.dart';
import '../core/icons/iconfont_widget.dart';
import '../core/db/app_database.dart';
import '../features/note/presentation/diary_page_simple.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _UserDrawerHeader extends StatefulWidget {
  const _UserDrawerHeader({
    required this.primary,
    required this.onGuestTap,
    required this.onSettingsTap,
  });

  final Color primary;
  final VoidCallback onGuestTap;
  final VoidCallback onSettingsTap;

  @override
  State<_UserDrawerHeader> createState() => _UserDrawerHeaderState();
}

class _UserDrawerHeaderState extends State<_UserDrawerHeader> {
  String _name = '';
  String _avatarPath = '';
  String _signature = '';

  @override
  void initState() {
    super.initState();
    _name = LocalData.getString(AuthRepositoryImpl.userDisplayNameKey);
    _avatarPath = LocalData.getString(AuthRepositoryImpl.userAvatarPathKey);
    _signature = LocalData.getString(AuthRepositoryImpl.userSignatureKey);
    print('[Drawer] name: $_name, avatarPath: $_avatarPath');
  }

  String _fullAvatarUrl() {
    final raw = _avatarPath.trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiClient.baseUrl}$raw';
    final url = '${ApiClient.baseUrl}/api/ufile/download/$raw';
    print('[Drawer] Full avatar URL: $url');
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final url = _fullAvatarUrl();
    final token = LocalData.getString(ApiClient.tokenKey);
    final isLoggedIn = token.isNotEmpty;

    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: Colors.black,
    );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Colors.black54,
      fontWeight: FontWeight.w600,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: isLoggedIn ? null : widget.onGuestTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        decoration: BoxDecoration(
          color: widget.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: widget.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.primary.withValues(alpha: 0.10),
                border: Border.all(
                  color: widget.primary.withValues(alpha: 0.22),
                ),
              ),
              child: ClipOval(
                child:
                    url.isNotEmpty
                        ? Image.network(
                          url,
                          headers: token.isNotEmpty ? {'x-token': token} : null,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.person_rounded),
                            );
                          },
                        )
                        : const Center(child: Icon(Icons.person_rounded)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _name.isNotEmpty ? _name : '未登录',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _signature.isNotEmpty
                        ? _signature
                        : (isLoggedIn ? '这个人很懒，什么都没写' : '点击这里去登录'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: subtitleStyle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: widget.onSettingsTap,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.primary.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    color: widget.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '设置',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _SettingsEntry(
                      icon: Icons.palette_outlined,
                      title: '主题颜色',
                      subtitle: '可在记事本页顶部调色板中切换',
                    ),
                    const SizedBox(height: 12),
                    _SettingsEntry(
                      icon: Icons.cloud_done_outlined,
                      title: '数据同步',
                      subtitle: '当前支持联网更新与本地离线访问',
                    ),
                    const SizedBox(height: 12),
                    _SettingsEntry(
                      icon: Icons.info_outline_rounded,
                      title: '更多设置',
                      subtitle: '后续可继续补充到账户、通知等选项',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsEntry extends StatelessWidget {
  const _SettingsEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: Colors.black.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySelector extends StatefulWidget {
  const _CategorySelector({
    required this.primary,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  final Color primary;
  final int? selectedCategoryId;
  final Function(int? categoryId) onCategorySelected;

  @override
  State<_CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<_CategorySelector> {
  final CategoryOfflineRepository _repo = CategoryOfflineRepository(
    CategoryApi(ApiClient()),
  );
  final NoteOfflineRepository _noteRepo = NoteOfflineRepository(
    NoteApi(ApiClient()),
  );
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  int _totalNotes = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _repo.loadAll();
      final visibleList =
          list.where((category) {
            final id = category['ID'];
            final isSystem = category['isSystem'] == true;
            if (id is! int) return true;
            if (!isSystem) return true;
            return _repo.isCategoryEnabled(id);
          }).toList();

      // 同时获取笔记总数
      try {
        final pageResult = await _noteRepo.loadPage(
          page: 1,
          pageSize: 1, // 只需要获取总数，不需要具体数据
          categoryId: null,
        );
        _totalNotes = pageResult.total;
      } catch (e) {
        // 如果获取失败，保持为 0
        _totalNotes = 0;
      }

      setState(() {
        _categories = visibleList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              '分类',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 全部按钮
          _buildCategoryButton(
            id: null,
            name: '全部',
            iconStr: 'apps',
            count: _totalNotes,
            isSelected: widget.selectedCategoryId == null,
          ),
          // 分类按钮列表
          ..._categories.map(
            (category) => _buildCategoryButton(
              id: category['ID'], // 修改：使用 'ID' 而不是 'id'
              name: category['name'] ?? '',
              iconStr: category['icon'] ?? '',
              color: category['color'],
              isSelected:
                  widget.selectedCategoryId == category['ID'], // 修改：使用 'ID'
            ),
          ),
          const SizedBox(height: 4),
          _buildManageCategoryEntry(),
        ],
      ),
    );
  }

  Widget _buildManageCategoryEntry() {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final navigator = Navigator.of(context);
          navigator.pop();
          final created = await navigator.push<bool>(
            MaterialPageRoute(builder: (_) => const CategoryManagePage()),
          );
          if (created == true && mounted) {
            await _loadCategories();
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('分类已更新')));
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20, color: widget.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '管理分类',
                  style: TextStyle(
                    color: widget.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: widget.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required int? id,
    required String name,
    required String iconStr,
    int? count,
    String? color,
    required bool isSelected,
  }) {
    Color buttonColor;
    if (isSelected) {
      buttonColor = widget.primary;
    } else if (color != null && color.startsWith('#')) {
      buttonColor = Color(int.parse(color.replaceFirst('#', '0xFF')));
    } else {
      buttonColor = Colors.grey.shade600;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
      decoration: BoxDecoration(
        color:
            isSelected
                ? widget.primary.withValues(alpha: 0.12)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          widget.onCategorySelected(id);
          Navigator.of(context).pop(); // 关闭侧栏
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              IconfontWidget(iconName: iconStr, size: 20, color: buttonColor),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: isSelected ? widget.primary : Colors.black87,
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '$count',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: widget.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeNavItemData {
  const _HomeNavItemData({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _HomeNavItem extends StatelessWidget {
  const _HomeNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.primary,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final iconColor = selected ? primary : Colors.black54;
    final base = Theme.of(context).textTheme.labelSmall;
    final textStyle = base
        ?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? primary : Colors.black54,
        )
        .copyWith(
          fontSize: ((base.fontSize ?? 11) / scale).clamp(10, 12),
          height: 1.0,
        );

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient:
                    selected
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary.withValues(alpha: 0.20),
                            primary.withValues(alpha: 0.08),
                          ],
                        )
                        : null,
              ),
              child: AnimatedScale(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                scale: selected ? 1.05 : 1.0,
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  int? _selectedCategoryId;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late final PageController _pageController = PageController();
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    ThemeProvider().syncFromApi();
    _updatePages();

    // 清理重复数据（异步执行，不阻塞UI）
    _cleanupDuplicateData();
  }

  Future<void> _cleanupDuplicateData() async {
    try {
      final db = AppDatabase();
      final deletedCount = await db.cleanupDuplicateNotes();
      if (deletedCount > 0) {
        print('清理了 $deletedCount 条重复笔记');
      }
    } catch (e) {
      print('清理重复数据失败: $e');
    }
  }

  void _openLoginFromDrawer() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const Login()));
  }

  void _openSettingsPage() {
    Navigator.of(context).pop();
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _SettingsPage()));
  }

  Future<void> _syncDataFromDrawer() async {
    Navigator.of(context).pop();
    try {
      final noteRepo = NoteOfflineRepository(NoteApi(ApiClient()));
      await noteRepo.syncSilently();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('数据同步完成')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('同步失败：$e')));
    }
  }

  Future<void> _logout() async {
    try {
      // 关闭侧栏
      Navigator.of(context).pop();

      // 执行退出登录
      final authRepo = AuthRepositoryImpl(AuthApi(ApiClient()));
      await authRepo.logout();

      // 显示提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('已退出登录，进入离线模式'),
          duration: Duration(seconds: 2),
        ),
      );

      // 触发重建，进入离线模式
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('退出失败：$e'), backgroundColor: Colors.red),
      );
    }
  }

  void _updatePages() {
    _pages = <Widget>[
      NoteListPage(
        key: ValueKey('category_$_selectedCategoryId'),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        categoryId: _selectedCategoryId,
      ),
      const DiaryPage(),
      const EchoPage(),
      const AiAssistantPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const items = <_HomeNavItemData>[
      _HomeNavItemData(label: '记事本', icon: Icons.note_alt_outlined),
      _HomeNavItemData(label: '日记', icon: Icons.book_outlined),
      _HomeNavItemData(label: '回响', icon: Icons.hourglass_empty_rounded),
      _HomeNavItemData(label: 'AI助手', icon: Icons.smart_toy_outlined),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _UserDrawerHeader(
                primary: colorScheme.primary,
                onGuestTap: _openLoginFromDrawer,
                onSettingsTap: _openSettingsPage,
              ),
              const SizedBox(height: 12),
              _CategorySelector(
                primary: colorScheme.primary,
                selectedCategoryId: _selectedCategoryId,
                onCategorySelected: (categoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _updatePages();
                  });
                },
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildDrawerActionButton(
                        icon: Icons.person_outline_rounded,
                        label: '个人资料',
                        color: colorScheme.primary,
                        onTap: _openSettingsPage,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildDrawerActionButton(
                        icon: Icons.sync_rounded,
                        label: '同步数据',
                        color: colorScheme.primary,
                        onTap: _syncDataFromDrawer,
                      ),
                    ),
                  ],
                ),
              ),
              // 退出登录按钮
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _logout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.red.shade300,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '退出登录',
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: _pages,
          ),
          // Floating bottom navigation
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: SafeArea(
              top: false,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: SizedBox(
                    height: 72,
                    child: Row(
                      children: List.generate(items.length, (index) {
                        final item = items[index];
                        final selected = index == _currentIndex;

                        return Expanded(
                          child: _HomeNavItem(
                            label: item.label,
                            icon: item.icon,
                            selected: selected,
                            primary: colorScheme.primary,
                            onTap: () {
                              if (_currentIndex == index) return;
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.10)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
