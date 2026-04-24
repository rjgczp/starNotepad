import 'package:flutter/material.dart';

import '../../../core/icons/iconfont_icons.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/sync/sync_offline_repository.dart';
import '../../../public/publicWidget.dart';

class CategoryCreatePage extends StatefulWidget {
  const CategoryCreatePage({
    super.key,
    this.categoryId,
    this.initialName,
    this.initialColor,
    this.initialIcon,
  });

  final int? categoryId;
  final String? initialName;
  final String? initialColor;
  final String? initialIcon;

  bool get isEditMode => categoryId != null;

  @override
  State<CategoryCreatePage> createState() => _CategoryCreatePageState();
}

class _CategoryCreatePageState extends State<CategoryCreatePage> {
  late final SyncOfflineRepository _repo = SyncOfflineRepository();

  final TextEditingController _nameController = TextEditingController();

  String _selectedColorHex = '#FFFFFF';
  String _selectedIconCss = 'icon-folder';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    final colorItems = ThemeProvider().colors;
    if (colorItems.isNotEmpty) {
      final firstColor = colorItems.first;
      _selectedColorHex =
          '#${(firstColor.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
    }
    if (widget.initialColor != null && widget.initialColor!.trim().isNotEmpty) {
      _selectedColorHex = widget.initialColor!.trim();
    }
    if (widget.initialIcon != null && widget.initialIcon!.trim().isNotEmpty) {
      _selectedIconCss =
          widget.initialIcon!.replaceFirst('iconfont ', '').trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _selectedIconLabel() {
    for (final item in IconfontIcons.all) {
      if (item.css == _selectedIconCss) {
        return item.label;
      }
    }
    return '选择图标';
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      Publicwidget.showToast(context, '请输入分类名称', false);
      return;
    }
    if (_submitting) return;

    setState(() => _submitting = true);
    try {
      if (widget.isEditMode) {
        await _repo.updateCategory(
          localId: widget.categoryId!,
          name: name,
          color: _selectedColorHex,
          icon: 'iconfont $_selectedIconCss',
        );
      } else {
        await _repo.createCategory(
          name: name,
          color: _selectedColorHex,
          icon: 'iconfont $_selectedIconCss',
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Publicwidget.showToast(context, e.toString(), false);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(widget.isEditMode ? '编辑分类' : '添加分类'),
        backgroundColor: cs.surface,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _submitting ? null : _submit,
            icon:
                _submitting
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                    : const Icon(Icons.check_rounded),
            label: Text(widget.isEditMode ? '保存' : '提交'),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _buildTipCard(cs),
            const SizedBox(height: 12),
            _buildNameCard(),
            const SizedBox(height: 12),
            _buildColorPicker(cs),
            const SizedBox(height: 12),
            _buildIconPicker(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
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
            child: Icon(Icons.info_outline_rounded, color: cs.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '分类说明',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '最多可添加 5 个分类。',
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

  Widget _buildNameCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _nameController,
        textInputAction: TextInputAction.done,
        maxLength: 20,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '输入分类名称…',
          prefixIcon: Icon(
            Icons.folder_open_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          border: InputBorder.none,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildColorPicker(ColorScheme cs) {
    final colorItems = ThemeProvider().colors;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('分类颜色'),
            const SizedBox(height: 10),
            if (colorItems.isEmpty)
              Text(
                '颜色加载中…',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children:
                    colorItems.map((item) {
                      final hex =
                          '#${(item.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
                      final isSelected =
                          _selectedColorHex.toLowerCase() == hex.toLowerCase();
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        child: Tooltip(
                          message: item.name,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? cs.primary
                                        : Colors.grey.shade300,
                                width: isSelected ? 2.5 : 1,
                              ),
                            ),
                            child:
                                isSelected
                                    ? Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                      color:
                                          item.color.computeLuminance() > 0.5
                                              ? Colors.black54
                                              : Colors.white,
                                    )
                                    : null,
                          ),
                        ),
                      );
                    }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPicker(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('分类图标'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showIconPickerSheet(cs),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      IconfontIcons.byName[_selectedIconCss] ??
                          Icons.folder_open_rounded,
                      size: 22,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedIconLabel(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIconPickerSheet(ColorScheme cs) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.3,
          maxChildSize: 0.75,
          builder: (ctx, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '选择图标',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.88,
                          ),
                      itemCount: IconfontIcons.all.length,
                      itemBuilder: (context, index) {
                        final item = IconfontIcons.all[index];
                        final isSelected = _selectedIconCss == item.css;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedIconCss = item.css);
                            Navigator.of(ctx).pop();
                          },
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? cs.primary.withValues(alpha: 0.14)
                                        : const Color(0xFFF5F6FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? cs.primary.withValues(alpha: 0.4)
                                          : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color: isSelected ? cs.primary : Colors.black54,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
