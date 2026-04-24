import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/icons/iconfont_icons.dart';
import '../../../core/sync/sync_offline_repository.dart';
import '../../../public/publicWidget.dart';

class NoteDetailPage extends StatefulWidget {
  const NoteDetailPage({super.key, required this.note});

  final Map<String, dynamic> note;

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late final SyncOfflineRepository _noteRepo = SyncOfflineRepository();
  late Map<String, dynamic> _note;

  @override
  void initState() {
    super.initState();
    _note = widget.note;
  }

  // ── Helpers ──

  Color _parseColor() {
    final v = _note['color']?.toString();
    if (v == null || v.isEmpty) return const Color(0xFF6C8EFF);
    try {
      var hex = v.replaceAll('#', '');
      if (hex.startsWith('0x') || hex.startsWith('0X')) hex = hex.substring(2);
      final n = int.parse(hex, radix: 16);
      return hex.length == 6 ? Color(0xFF000000 | n) : Color(n);
    } catch (_) {
      return const Color(0xFF6C8EFF);
    }
  }

  IconData? _parseIcon() {
    final s = _note['icon']?.toString();
    if (s == null || s.isEmpty) return null;
    return IconfontIcons.fromCssClass(s);
  }

  bool _flag(String key) => _note[key] == true || _note[key]?.toString() == '1';

  bool get _isTop => _flag('isTop');
  bool get _isHighlight => _flag('isHighlight');
  bool get _isReminder => _flag('isReminder');

  String _htmlToPlain(String? html) {
    if (html == null) return '';
    var s = html.trim();
    if (s.isEmpty) return '';
    s = s.replaceAll(RegExp(r'<\s*br\s*/?>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'</\s*p\s*>', caseSensitive: false), '\n');
    s = s.replaceAll(RegExp(r'<\s*p[^>]*>', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'<[^>]+>'), '');
    s = s
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return s.trim();
  }

  TextSpan _htmlToSpan(String? html, TextStyle baseStyle) {
    if (html == null || html.trim().isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final spans = <TextSpan>[];
    final styleStack = <_HtmlStyleItem>[];
    final tagReg = RegExp(r'<[^>]+>');

    TextStyle currentStyle() {
      var style = baseStyle;
      for (final item in styleStack) {
        style = style.merge(item.style);
      }
      return style;
    }

    void addText(String raw) {
      if (raw.isEmpty) return;
      final text = _decodeHtmlText(raw);
      if (text.isEmpty) return;
      spans.add(TextSpan(text: text, style: currentStyle()));
    }

    void popStyle(Set<String> names) {
      for (var i = styleStack.length - 1; i >= 0; i--) {
        if (names.contains(styleStack[i].name)) {
          styleStack.removeAt(i);
          return;
        }
      }
    }

    var cursor = 0;
    for (final m in tagReg.allMatches(html)) {
      addText(html.substring(cursor, m.start));
      final tag = html.substring(m.start, m.end);
      final lower = tag.toLowerCase();

      if (RegExp(r'^<\s*br\s*/?\s*>$').hasMatch(lower) ||
          RegExp(r'^<\s*/\s*(p|div|li)\s*>$').hasMatch(lower)) {
        spans.add(TextSpan(text: '\n', style: currentStyle()));
      } else if (RegExp(r'^<\s*(b|strong)(\s+[^>]*)?>$').hasMatch(lower)) {
        styleStack.add(
          const _HtmlStyleItem('b', TextStyle(fontWeight: FontWeight.w700)),
        );
      } else if (RegExp(r'^<\s*/\s*(b|strong)\s*>$').hasMatch(lower)) {
        popStyle({'b'});
      } else if (RegExp(r'^<\s*(i|em)(\s+[^>]*)?>$').hasMatch(lower)) {
        styleStack.add(
          const _HtmlStyleItem('i', TextStyle(fontStyle: FontStyle.italic)),
        );
      } else if (RegExp(r'^<\s*/\s*(i|em)\s*>$').hasMatch(lower)) {
        popStyle({'i'});
      } else if (RegExp(r'^<\s*u(\s+[^>]*)?>$').hasMatch(lower)) {
        styleStack.add(
          const _HtmlStyleItem(
            'u',
            TextStyle(decoration: TextDecoration.underline),
          ),
        );
      } else if (RegExp(r'^<\s*/\s*u\s*>$').hasMatch(lower)) {
        popStyle({'u'});
      } else if (RegExp(r'^<\s*(s|strike|del)(\s+[^>]*)?>$').hasMatch(lower)) {
        styleStack.add(
          const _HtmlStyleItem(
            's',
            TextStyle(decoration: TextDecoration.lineThrough),
          ),
        );
      } else if (RegExp(r'^<\s*/\s*(s|strike|del)\s*>$').hasMatch(lower)) {
        popStyle({'s'});
      } else if (RegExp(r'^<\s*span(\s+[^>]*)?>$').hasMatch(lower)) {
        final spanStyle = _styleFromSpanTag(tag);
        if (spanStyle != null) {
          styleStack.add(_HtmlStyleItem('span', spanStyle));
        }
      } else if (RegExp(r'^<\s*/\s*span\s*>$').hasMatch(lower)) {
        popStyle({'span'});
      }

      cursor = m.end;
    }

    addText(html.substring(cursor));
    return TextSpan(style: baseStyle, children: spans);
  }

  String _decodeHtmlText(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
  }

  TextStyle? _styleFromSpanTag(String tag) {
    final styleMatch = RegExp(
      r'''style\s*=\s*['"]([^'"]+)['"]''',
      caseSensitive: false,
    ).firstMatch(tag);
    if (styleMatch == null) return null;

    Color? color;
    double? fontSize;
    final styleText = styleMatch.group(1) ?? '';
    final declarations = styleText.split(';');
    for (final declaration in declarations) {
      final parts = declaration.split(':');
      if (parts.length != 2) continue;
      final key = parts[0].trim().toLowerCase();
      final value = parts[1].trim();
      if (key == 'color') {
        color = _parseCssColor(value);
      } else if (key == 'font-size') {
        fontSize = _parseCssFontSize(value);
      }
    }

    if (color == null && fontSize == null) return null;
    return TextStyle(color: color, fontSize: fontSize);
  }

  Color? _parseCssColor(String value) {
    var v = value.trim().toLowerCase();
    if (v.startsWith('#')) {
      v = v.substring(1);
      if (v.length == 3) {
        v = '${v[0]}${v[0]}${v[1]}${v[1]}${v[2]}${v[2]}';
      }
      if (v.length == 6) {
        final n = int.tryParse(v, radix: 16);
        if (n != null) return Color(0xFF000000 | n);
      }
      return null;
    }

    final rgb = RegExp(
      r'rgb\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\)',
    ).firstMatch(v);
    if (rgb != null) {
      final r = int.tryParse(rgb.group(1) ?? '');
      final g = int.tryParse(rgb.group(2) ?? '');
      final b = int.tryParse(rgb.group(3) ?? '');
      if (r != null && g != null && b != null) {
        return Color.fromARGB(
          255,
          r.clamp(0, 255),
          g.clamp(0, 255),
          b.clamp(0, 255),
        );
      }
    }
    return null;
  }

  double? _parseCssFontSize(String value) {
    final m = RegExp(r'([0-9]+(?:\.[0-9]+)?)').firstMatch(value.trim());
    if (m == null) return null;
    return double.tryParse(m.group(1) ?? '');
  }

  String _plainToHtml(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    return lines.map((l) => '<p>${l.trim()}</p>').join();
  }

  String _dateLabel() {
    final raw = _note['createdAt']?.toString();
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      const w = {
        DateTime.monday: '星期一',
        DateTime.tuesday: '星期二',
        DateTime.wednesday: '星期三',
        DateTime.thursday: '星期四',
        DateTime.friday: '星期五',
        DateTime.saturday: '星期六',
        DateTime.sunday: '星期日',
      };
      return '${dt.year}年${dt.month}月${dt.day}日 ${w[dt.weekday] ?? ''}';
    } catch (_) {
      return raw;
    }
  }

  String _timeLabel() {
    final raw = _note['createdAt']?.toString();
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  // ── Edit ──

  Future<void> _editNote() async {
    final titleCtrl = TextEditingController(
      text: _note['title']?.toString() ?? '',
    );
    final contentCtrl = TextEditingController(
      text: _htmlToPlain(_note['content']?.toString()),
    );
    final primary = _parseColor();
    var selectedIconCss =
        (_note['icon']?.toString() ?? '').replaceFirst('iconfont ', '').trim();
    var isTop = _isTop;
    var isHighlight = _isHighlight;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
              final maxHeight = MediaQuery.of(ctx).size.height * 0.82;

              return SafeArea(
                top: false,
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '编辑',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: titleCtrl,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '标题',
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: contentCtrl,
                                    minLines: 4,
                                    maxLines: 8,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      height: 1.5,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '内容',
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '图标',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked =
                                          await _showEditIconPickerSheet(
                                            ctx,
                                            primary,
                                            selectedIconCss,
                                          );
                                      if (picked != null) {
                                        setSheetState(
                                          () => selectedIconCss = picked,
                                        );
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primary.withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          if (selectedIconCss.isNotEmpty) ...[
                                            Icon(
                                              IconfontIcons
                                                      .byName[selectedIconCss] ??
                                                  Icons.help_outline,
                                              size: 20,
                                              color: primary,
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap:
                                                  () => setSheetState(
                                                    () => selectedIconCss = '',
                                                  ),
                                              child: Text(
                                                '清除',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ] else ...[
                                            Icon(
                                              Icons.add_reaction_outlined,
                                              size: 20,
                                              color: Colors.grey.shade500,
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_forward_ios_rounded,
                                              size: 14,
                                              color: Colors.grey.shade400,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '设置',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _buildEditToggleChip(
                                        label: '置顶',
                                        icon: Icons.push_pin_outlined,
                                        value: isTop,
                                        primary: primary,
                                        onTap:
                                            () => setSheetState(
                                              () => isTop = !isTop,
                                            ),
                                      ),
                                      _buildEditToggleChip(
                                        label: '高亮',
                                        icon: Icons.highlight_outlined,
                                        value: isHighlight,
                                        primary: primary,
                                        onTap:
                                            () => setSheetState(
                                              () => isHighlight = !isHighlight,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('取消'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed:
                                      () =>
                                          Navigator.pop(ctx, <String, dynamic>{
                                            'title': titleCtrl.text.trim(),
                                            'content': contentCtrl.text.trim(),
                                            'icon': selectedIconCss,
                                            'isTop': isTop,
                                            'isHighlight': isHighlight,
                                          }),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text('保存'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
    );

    if (result == null) return;
    final newTitle = result['title']?.toString() ?? '';
    final newContent = result['content']?.toString() ?? '';
    final newIconCss = result['icon']?.toString() ?? '';
    final updated =
        Map<String, dynamic>.from(_note)
          ..['title'] = newTitle
          ..['content'] = _plainToHtml(newContent)
          ..['icon'] = newIconCss.isEmpty ? null : 'iconfont $newIconCss'
          ..['isTop'] = result['isTop'] == true
          ..['isHighlight'] = result['isHighlight'] == true;

    try {
      await _noteRepo.updateLocalFirst(note: updated);
      if (!mounted) return;
      setState(() => _note = updated);
      Publicwidget.showToast(context, '已更新', true);
    } catch (e) {
      if (!mounted) return;
      Publicwidget.showToast(context, e.toString(), false);
    }
  }

  Widget _buildEditToggleChip({
    required String label,
    required IconData icon,
    required bool value,
    required Color primary,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value ? primary.withValues(alpha: 0.14) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? primary.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: value ? primary : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value ? primary : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEditIconPickerSheet(
    BuildContext context,
    Color primary,
    String selectedIconCss,
  ) {
    return showModalBottomSheet<String>(
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
                        final isSelected = selectedIconCss == item.css;
                        return GestureDetector(
                          onTap: () => Navigator.of(ctx).pop(item.css),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? primary.withValues(alpha: 0.14)
                                        : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      isSelected
                                          ? primary.withValues(alpha: 0.4)
                                          : Colors.transparent,
                                ),
                              ),
                              child: Icon(
                                item.icon,
                                size: 18,
                                color:
                                    isSelected ? primary : Colors.grey.shade700,
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = _parseColor();
    final title = _note['title']?.toString().trim() ?? '';
    final content = _note['content']?.toString() ?? '';
    final plainContent = _htmlToPlain(content);
    final noteIcon = _parseIcon();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.black,
                      ),
                      tooltip: '编辑',
                      onPressed: _editNote,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (_isTop || _isHighlight || _isReminder)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_isTop)
                          _headerTag(Icons.push_pin_rounded, '置顶', primary),
                        if (_isHighlight)
                          _headerTag(Icons.star_rounded, '高亮', primary),
                        if (_isReminder)
                          _headerTag(
                            Icons.notifications_rounded,
                            '提醒',
                            primary,
                          ),
                      ],
                    ),
                  ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (noteIcon != null)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(top: 2, right: 12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(noteIcon, size: 20, color: primary),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.isNotEmpty ? title : '(无标题)',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111111),
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_dateLabel()}  ${_timeLabel()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child:
                      plainContent.isNotEmpty
                          ? SelectableText.rich(
                            _htmlToSpan(
                              content,
                              TextStyle(
                                fontSize: 16,
                                height: 1.8,
                                color: Colors.grey.shade800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.8,
                              color: Colors.grey.shade800,
                              letterSpacing: 0.2,
                            ),
                          )
                          : Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 60),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.note_outlined,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '暂无内容',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerTag(IconData icon, String label, Color primary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HtmlStyleItem {
  const _HtmlStyleItem(this.name, this.style);

  final String name;
  final TextStyle style;
}
