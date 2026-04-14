import 'package:flutter/material.dart';

import '../../../core/icons/iconfont_widget.dart';
import '../../../core/network/api_client.dart';
import '../data/category_api.dart';
import '../data/category_offline_repository.dart';
import 'category_create_page.dart';

class CategoryManagePage extends StatefulWidget {
  const CategoryManagePage({super.key});

  @override
  State<CategoryManagePage> createState() => _CategoryManagePageState();
}

class _CategoryManagePageState extends State<CategoryManagePage> {
  final CategoryOfflineRepository _repo = CategoryOfflineRepository(
    CategoryApi(ApiClient()),
  );

  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  bool _savingOrder = false;
  bool _hasChanges = false;

  Future<bool> _handleBack() async {
    Navigator.pop(context, _hasChanges);
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final list = await _repo.loadAll();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('加载分类失败：$e')));
    }
  }

  Future<void> _toggleSystemCategory(Map<String, dynamic> category) async {
    final id = category['ID'];
    if (id is! int) return;
    final isEnabled = _repo.isCategoryEnabled(id);
    await _repo.setCategoryEnabled(id, !isEnabled);
    _hasChanges = true;
    await _loadCategories();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(isEnabled ? '已停用分类' : '已启用分类')));
  }

  Future<void> _openCreatePage() async {
    final changed = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CategoryCreatePage()));
    if (changed == true) {
      _hasChanges = true;
      await _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类创建成功')));
    }
  }

  Future<void> _openEditPage(Map<String, dynamic> category) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder:
            (_) => CategoryCreatePage(
              categoryId: category['ID'] as int?,
              initialName: category['name']?.toString(),
              initialColor: category['color']?.toString(),
              initialIcon: category['icon']?.toString(),
            ),
      ),
    );
    if (changed == true) {
      _hasChanges = true;
      await _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类已更新')));
    }
  }

  Future<void> _deleteCategory(Map<String, dynamic> category) async {
    final id = category['ID'];
    if (id is! int) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('删除分类'),
            content: Text('确定删除分类“${category['name'] ?? ''}”吗？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('删除'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await _repo.deleteCategory(id: id);
      _hasChanges = true;
      await _loadCategories();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('分类已删除')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _saveOrder() async {
    if (_savingOrder) return;
    setState(() => _savingOrder = true);
    try {
      final ids = _categories.map((e) => e['ID']).whereType<int>().toList();
      await _repo.saveCategoryOrder(ids);
    } finally {
      if (mounted) {
        setState(() => _savingOrder = false);
      }
    }
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _categories.removeAt(oldIndex);
      _categories.insert(newIndex, item);
    });
    _hasChanges = true;
    _saveOrder();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _handleBack,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          leading: IconButton(
            onPressed: _handleBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          title: const Text('管理分类'),
          backgroundColor: cs.surface,
          foregroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: [
            TextButton.icon(
              onPressed: _openCreatePage,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加分类'),
              style: TextButton.styleFrom(foregroundColor: Colors.black),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child:
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.drag_indicator_rounded,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '长按可调整分类显示顺序',
                                style: TextStyle(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  fontSize: 13,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child:
                            _categories.isEmpty
                                ? Center(
                                  child: Text(
                                    '暂无分类',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                )
                                : ReorderableListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    24,
                                  ),
                                  itemCount: _categories.length,
                                  onReorder: _reorder,
                                  buildDefaultDragHandles: false,
                                  proxyDecorator: (child, index, animation) {
                                    return AnimatedBuilder(
                                      animation: animation,
                                      builder: (context, _) {
                                        return Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: child,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  itemBuilder: (context, index) {
                                    final category = _categories[index];
                                    return _buildCategoryTile(
                                      key: ValueKey(category['ID']),
                                      category: category,
                                      index: index,
                                      cs: cs,
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildTextActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    required Key key,
    required Map<String, dynamic> category,
    required int index,
    required ColorScheme cs,
  }) {
    final color = _parseColor(category['color']?.toString()) ?? cs.primary;
    final isSystem = category['isSystem'] == true;
    final categoryId = category['ID'];
    final isEnabled =
        categoryId is int ? _repo.isCategoryEnabled(categoryId) : true;
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 28,
                height: 40,
                alignment: Alignment.center,
                child: Icon(
                  Icons.drag_indicator_rounded,
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category['name']?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if ((category['icon']?.toString().trim().isNotEmpty ??
                          false))
                        IconfontWidget(
                          iconName: category['icon']!.toString(),
                          size: 15,
                          color: color,
                        ),
                      if ((category['icon']?.toString().trim().isNotEmpty ??
                          false))
                        const SizedBox(width: 8),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category['color']?.toString() ?? '',
                        style: TextStyle(
                          color: Colors.black.withValues(alpha: 0.52),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 28,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: Colors.black.withValues(alpha: 0.08),
            ),
            if (isSystem) ...[
              _buildTextActionButton(
                label: isEnabled ? '停用' : '启用',
                color:
                    isEnabled ? Colors.orange.shade400 : Colors.green.shade500,
                onTap: () => _toggleSystemCategory(category),
              ),
            ] else ...[
              _buildActionButton(
                icon: Icons.edit_outlined,
                color: cs.primary,
                onTap: () => _openEditPage(category),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                icon: Icons.delete_outline_rounded,
                color: Colors.red.shade300,
                onTap: () => _deleteCategory(category),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }

  Color? _parseColor(String? raw) {
    if (raw == null || raw.isEmpty || !raw.startsWith('#')) return null;
    return Color(int.parse(raw.replaceFirst('#', '0xFF')));
  }
}
