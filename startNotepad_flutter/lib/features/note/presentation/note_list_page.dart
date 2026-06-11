import 'dart:async';

import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:startnotepad_flutter/core/icons/iconfont_icons.dart';
import 'package:startnotepad_flutter/core/theme/theme_provider.dart';
import 'package:startnotepad_flutter/core/sync/sync_offline_repository.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_create_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_detail_page.dart';
import 'package:startnotepad_flutter/public/publicWidget.dart';

// ── 「素白留白」设计令牌 ──
const Color _kCanvas = Color(0xFFFAFAF8); // 暖白画布
const Color _kCard = Colors.white;
const Color _kInk = Color(0xFF1C1C1E); // 主文字（近黑）
const Color _kInkSub = Color(0xFF8A8A8E); // 辅助文字（中灰）
const Color _kHairline = Color(0xFFEDEDE9); // 极淡分隔/描边

class NoteListPage extends StatefulWidget {

  const NoteListPage({super.key, this.onOpenDrawer, this.categoryId});

  final VoidCallback? onOpenDrawer;
  final int? categoryId;

  @override
  State<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage>
    with SingleTickerProviderStateMixin {
  late final SyncOfflineRepository _repo = SyncOfflineRepository();
  Future<PageResult>? _future;

  // 分页相关
  List<Map<String, dynamic>> _allNotes = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  final _searchController = TextEditingController();
  String _query = '';
  int _gridColumns = 2;

  late final AnimationController _layoutAC = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1.0,
  );

  static const _palette = <Color>[
    Color(0xFF6C8EFF),
    Color(0xFFFF8A65),
    Color(0xFF66BB6A),
    Color(0xFFEC407A),
    Color(0xFFAB47BC),
    Color(0xFF26C6DA),
    Color(0xFFFFCA28),
    Color(0xFF8D6E63),
  ];

  @override
  void initState() {
    super.initState();
    _future = _load();

    // 添加滚动监听器
    _scrollController.addListener(() {
      final threshold = _scrollController.position.maxScrollExtent - 200;
      if (_scrollController.position.pixels >= threshold) {
        print(
          'Scroll position: ${_scrollController.position.pixels}, max: ${_scrollController.position.maxScrollExtent}, threshold: $threshold',
        );
        print(
          'Scroll to bottom triggered, _hasMore: $_hasMore, _isLoadingMore: $_isLoadingMore',
        );
        _loadMore();
      }
    });
  }

  @override
  void didUpdateWidget(NoteListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 如果 categoryId 改变，重新加载数据
    if (oldWidget.categoryId != widget.categoryId) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _layoutAC.dispose();
    super.dispose();
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

  Future<void> _toggleColumns() async {
    await _layoutAC.reverse();
    setState(() {
      _gridColumns = _gridColumns == 1 ? 2 : 1;
    });
    _layoutAC.forward();
  }

  Future<PageResult> _load() async {
    try {
      // 重置分页状态
      _currentPage = 1;
      _allNotes.clear();
      _hasMore = true;

      final pageResult = await _repo.loadPage(
        page: _currentPage,
        pageSize: _pageSize,
        categoryId: widget.categoryId,
      );

      _allNotes.addAll(pageResult.notes);

      // 检查是否还有更多数据
      if (pageResult.notes.length < _pageSize ||
          _allNotes.length >= pageResult.total) {
        _hasMore = false;
      }
      print(
        'Initial load: notes=${pageResult.notes.length}, total=${pageResult.total}, _hasMore=$_hasMore',
      );

      return pageResult;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> _loadMore() async {
    print(
      '_loadMore called, _hasMore: $_hasMore, _isLoadingMore: $_isLoadingMore',
    );
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      _currentPage++;

      final pageResult = await _repo.loadPage(
        page: _currentPage,
        pageSize: _pageSize,
        categoryId: widget.categoryId,
      );

      setState(() {
        _allNotes.addAll(pageResult.notes);

        // 检查是否还有更多数据
        if (pageResult.notes.length < _pageSize ||
            _allNotes.length >= pageResult.total) {
          _hasMore = false;
        }

        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      // 错误时不显示错误，只是停止加载更多
    }
  }

  Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;

    if (value is int) {
      final c = value;
      if (c >= 0 && c <= 0xFFFFFF) return Color(0xFF000000 | c);
      return Color(c);
    }

    if (value is num) {
      final c = value.toInt();
      if (c >= 0 && c <= 0xFFFFFF) return Color(0xFF000000 | c);
      return Color(c);
    }

    if (value is String) {
      var s = value.trim();
      if (s.isEmpty) return null;

      if (s.startsWith('#')) s = s.substring(1);
      if (s.startsWith('0x') || s.startsWith('0X')) s = s.substring(2);

      final hex = s.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (hex.length == 6) {
        final v = int.tryParse(hex, radix: 16);
        if (v == null) return null;
        return Color(0xFF000000 | v);
      }
      if (hex.length == 8) {
        final v = int.tryParse(hex, radix: 16);
        if (v == null) return null;
        return Color(v);
      }
    }

    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is int) {
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      if (value > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is num) {
      return _parseDate(value.toInt());
    }
    if (value is String) {
      final s = value.trim();
      if (s.isEmpty) return null;

      final asInt = int.tryParse(s);
      if (asInt != null) return _parseDate(asInt);

      final normalized = s.replaceAll(' ', 'T');
      return DateTime.tryParse(normalized) ?? DateTime.tryParse(s);
    }
    return null;
  }

  String _formatDateCn(DateTime dt) {
    const weekday = <int, String>{
      DateTime.monday: '星期一',
      DateTime.tuesday: '星期二',
      DateTime.wednesday: '星期三',
      DateTime.thursday: '星期四',
      DateTime.friday: '星期五',
      DateTime.saturday: '星期六',
      DateTime.sunday: '星期日',
    };
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final w = weekday[dt.weekday] ?? '';
    return '$y年$m月$d日 $w';
  }

  Future<void> _refresh() async {
    try {
      await _repo.syncSilently();
    } catch (e) {
      if (mounted) {
        Publicwidget.showToast(context, '同步失败：$e', false);
      }
    }

    if (!mounted) return;
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openCreate() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const NoteCreatePage()));
    if (created == true && mounted) {
      await _refresh();
    }
  }

  // ── Greeting based on time of day ──
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 6) return '夜深了 🌙';
    if (h < 12) return '早上好 ☀️';
    if (h < 14) return '中午好 🌤';
    if (h < 18) return '下午好 ☁️';
    return '晚上好 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;

    return Scaffold(
      backgroundColor: _kCanvas,
      floatingActionButton: _BreathingFab(
        primary: primary,
        onPressed: _openCreate,
      ),


      body: FutureBuilder<PageResult>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final isLoading = snapshot.connectionState != ConnectionState.done;

          return RefreshIndicator(
            onRefresh: _refresh,
            color: primary,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Hero App Bar ──
                _buildSliverAppBar(context, primary, data),

                // ── Search & Toggle Row ──
                SliverToBoxAdapter(child: _buildSearchBar(primary)),

                // ── Content ──
                if (isLoading)
                  _buildLoadingSliver()
                else if (snapshot.hasError)
                  _buildErrorSliver(context, snapshot.error)
                else
                  ..._buildNoteGrid(context, _allNotes, data?.total),

                // 加载更多指示器
                if (_isLoadingMore)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),

                // 没有更多数据提示
                if (!_hasMore && _allNotes.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          '没有更多了',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Theme color picker bottom sheet ──
  void _showThemeColorPicker(BuildContext context) {
    final provider = ThemeProvider();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            final colors = provider.colors;
            final current = provider.primaryColor;

            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.palette_rounded, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        '主题颜色',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${colors.length} 种配色',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (colors.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        '暂无颜色数据',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 14,
                      children:
                          colors.map((item) {
                            final isSelected =
                                (current.toARGB32() & 0xFFFFFF) ==
                                (item.color.toARGB32() & 0xFFFFFF);
                            return GestureDetector(
                              onTap: () {
                                provider.setColor(item.color);
                                Navigator.of(ctx).pop();
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: item.color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:
                                            isSelected
                                                ? Colors.black87
                                                : Colors.grey.shade200,
                                        width: isSelected ? 2.5 : 1.5,
                                      ),
                                      boxShadow:
                                          isSelected
                                              ? [
                                                BoxShadow(
                                                  color: item.color.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                              : null,
                                    ),
                                    child:
                                        isSelected
                                            ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            )
                                            : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                          isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                      color:
                                          isSelected
                                              ? Colors.black87
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Sliver App Bar with expressive hero header ──
  Widget _buildSliverAppBar(
    BuildContext context,
    Color primary,
    PageResult? data,
  ) {
    final count = data?.total ?? 0;
    return SliverAppBar(
      expandedHeight: 178,
      floating: false,
      pinned: true,
      backgroundColor: _kCanvas,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 64,
      leading:
          widget.onOpenDrawer != null
              ? Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _RoundIconButton(
                  icon: Icons.menu_rounded,
                  onTap: widget.onOpenDrawer!,
                ),
              )
              : null,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _RoundIconButton(
            icon: Icons.palette_outlined,
            tooltip: '切换主题色',
            accent: primary,
            onTap: () => _showThemeColorPicker(context),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // 顶部一抹极淡的主题色光晕，呼应「星空」意境
            Positioned(
              top: -90,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primary.withValues(alpha: 0.14),
                      primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 56, 22, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 日期 + 星标点缀
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _todayLine(),
                          style: TextStyle(
                            color: primary.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _greeting(),
                      style: const TextStyle(
                        color: _kInk,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // 记录条数信息条
                    Row(
                      children: [
                        Text(
                          count > 0 ? '$count' : '0',
                          style: TextStyle(
                            color: primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          '条记录',
                          style: TextStyle(
                            color: _kInkSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: _kInkSub,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '安静地写下此刻',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _kInkSub,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        collapseMode: CollapseMode.parallax,
      ),
    );
  }

  // ── 顶部日期行，例：6月10日 星期二 ──
  String _todayLine() {
    final now = DateTime.now();
    const weekday = <int, String>{
      DateTime.monday: '星期一',
      DateTime.tuesday: '星期二',
      DateTime.wednesday: '星期三',
      DateTime.thursday: '星期四',
      DateTime.friday: '星期五',
      DateTime.saturday: '星期六',
      DateTime.sunday: '星期日',
    };
    return '${now.month}月${now.day}日 ${weekday[now.weekday] ?? ''}';
  }



  // ── Search Bar：胶囊搜索 + 视图切换 ──
  Widget _buildSearchBar(Color primary) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
      child: Row(
        children: [
          // Search field
          Expanded(
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: _kHairline, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: _kInkSub,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: _kInk,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        hintText: '搜索你的记录…',
                        hintStyle: TextStyle(
                          color: _kInkSub,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: _kHairline,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: _kInkSub,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Grid toggle
          GestureDetector(
            onTap: _toggleColumns,
            child: Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder:
                    (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Icon(
                  _gridColumns == 1
                      ? Icons.grid_view_rounded
                      : Icons.view_agenda_rounded,
                  key: ValueKey(_gridColumns),
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── Loading Skeleton ──
  SliverToBoxAdapter _buildLoadingSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          children: List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kHairline, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _kHairline,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 120,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _kHairline,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kHairline,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 180,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _kHairline,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // ── Error State ──
  SliverToBoxAdapter _buildErrorSliver(BuildContext context, Object? error) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_rounded,
                size: 36,
                color: Colors.red.shade300,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('重试'),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ──
  SliverToBoxAdapter _buildEmptySliver({bool isSearch = false}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        child: Column(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0FF),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearch ? Icons.search_off_rounded : Icons.note_add_rounded,
                size: 42,
                color: const Color(0xFF6C8EFF),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? '没有匹配的笔记' : '还没有笔记',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearch ? '试试其他关键词吧' : '点击右下角按钮，开始你的第一条记录',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  // ── Note Grid ──
  List<Widget> _buildNoteGrid(
    BuildContext context,
    List<Map<String, dynamic>> rawItems,
    int? totalCount,
  ) {
    final q = _query.trim().toLowerCase();
    final items =
        q.isEmpty
            ? rawItems
            : rawItems.where((item) {
              final title = item['title']?.toString().toLowerCase() ?? '';
              final content = item['content']?.toString().toLowerCase() ?? '';
              return title.contains(q) || content.contains(q);
            }).toList();

    if (items.isEmpty && rawItems.isEmpty) {
      return [_buildEmptySliver()];
    }
    if (items.isEmpty) {
      return [_buildEmptySliver(isSearch: true)];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        sliver: SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Text(
                  '全部笔记',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${totalCount ?? items.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _kInkSub,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
      SliverFadeTransition(
        opacity: _layoutAC,
        sliver: SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          sliver: SliverLayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              const spacing = 12.0;
              final maxColumns = width >= 560 ? 3 : 2;
              final crossAxisCount = _gridColumns.clamp(1, maxColumns);
              final itemWidth =
                  (width - (crossAxisCount - 1) * spacing) / crossAxisCount;
              final itemHeight =
                  _gridColumns == 1 ? itemWidth * 0.45 : itemWidth * 1.12;

              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _noteCard(context, items, index),
                  childCount: items.length,
                ),
              );
            },
          ),
        ),
      ),
    ];
  }

  // ── Single Note Card ──
  Widget _noteCard(
    BuildContext context,
    List<Map<String, dynamic>> items,
    int index,
  ) {
    final item = items[index];
    final title = item['title']?.toString().trim();
    final content = item['content']?.toString() ?? '';
    final isTop = item['isTop'] == true || item['isTop']?.toString() == '1';
    final isReminder =
        item['isReminder'] == true || item['isReminder']?.toString() == '1';
    final isHighlight =
        item['isHighlight'] == true || item['isHighlight']?.toString() == '1';

    // Parse icon (e.g., "iconfont icon-coffee")
    IconData? noteIcon;
    final iconStr = item['icon']?.toString();
    if (iconStr != null && iconStr.startsWith('iconfont ')) {
      noteIcon = IconfontIcons.fromCssClass(iconStr);
    }

    final backendColor = _parseColor(
      item['color'] ??
          item['bgColor'] ??
          item['backgroundColor'] ??
          item['BackgroundColor'],
    );
    final baseColor = backendColor ?? _palette[index % _palette.length];
    final isSingle = _gridColumns == 1;

    final dt = _parseDate(
      item['updatedAt'] ??
          item['UpdatedAt'] ??
          item['createdAt'] ??
          item['CreatedAt'] ??
          item['date'],
    );
    final footer = dt != null ? _formatDateCn(dt) : '';

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighlight ? baseColor.withValues(alpha: 0.35) : _kHairline,
          width: 1,
        ),
        boxShadow: [
          // 极柔弥散阴影，靠层级而非线条分隔
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          splashColor: baseColor.withValues(alpha: 0.06),
          highlightColor: baseColor.withValues(alpha: 0.03),
          onTap: () {
            Navigator.of(context).push<void>(
              PageTransition(
                type: PageTransitionType.rightToLeft,
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: NoteDetailPage(note: item),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.fromLTRB(18, 16, 18, isSingle ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Title row：彩色小圆点作为唯一强调 ──
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (title != null && title.isNotEmpty) ? title : '无标题',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _kInk,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          height: 1.2,
                        ),
                      ),
                    ),
                    if (noteIcon != null)
                      Icon(noteIcon, size: 15, color: _kInkSub),
                    if (isReminder)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 15,
                          color: _kInkSub,
                        ),
                      ),
                    if (isTop)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(
                          Icons.push_pin_outlined,
                          size: 15,
                          color: _kInkSub,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // ── Content body ──
                Flexible(
                  child: Text.rich(
                    _htmlToSpan(
                      content,
                      const TextStyle(
                        height: 1.55,
                        fontSize: 13.5,
                        color: Color(0xFF55555A),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    maxLines: isSingle ? 2 : 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                if (footer.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    footer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: _kInkSub,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── 呼吸光晕的写笔记按钮 ──
class _BreathingFab extends StatefulWidget {
  const _BreathingFab({required this.primary, required this.onPressed});

  final Color primary;
  final VoidCallback onPressed;

  @override
  State<_BreathingFab> createState() => _BreathingFabState();
}

class _BreathingFabState extends State<_BreathingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ac,
      builder: (context, child) {
        final glow = 0.18 + _ac.value * 0.16;
        final spread = 1.0 + _ac.value * 3.0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: widget.primary.withValues(alpha: glow),
                blurRadius: 22,
                spreadRadius: spread,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        );
      },
      child: FloatingActionButton.extended(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.edit_note_rounded),
        label: const Text(
          '写笔记',
          style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3),
        ),
        backgroundColor: widget.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}


// ── 圆形玻璃质感图标按钮（顶栏用） ──
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.accent,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _kHairline, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: accent ?? _kInk),
        ),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _HtmlStyleItem {
  const _HtmlStyleItem(this.name, this.style);

  final String name;
  final TextStyle style;
}

