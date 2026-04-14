import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lunar/lunar.dart';
import 'package:page_transition/page_transition.dart';
import 'package:startnotepad_flutter/tools/localData.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/features/echo/presentation/echo_detail_page.dart';
import 'package:startnotepad_flutter/features/history_day/data/history_day_api.dart';

class EchoPage extends StatefulWidget {
  const EchoPage({super.key});

  @override
  State<EchoPage> createState() => _EchoPageState();
}

class _EchoPageState extends State<EchoPage> {
  static const String _cacheKey = 'echo_history_day_future_cache';
  static const String _cacheUpdatedAtKey =
      'echo_history_day_future_cache_updated_at';

  late final HistoryDayApi _historyDayApi;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _rawData = {};
  List<Map<String, dynamic>> _events = [];
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  int _bannerIndex = 0;

  @override
  void initState() {
    super.initState();
    _historyDayApi = HistoryDayApi(ApiClient());
    _loadData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = _readCachedFutureData();
    var hasLocalData = false;
    if (cached != null) {
      hasLocalData = _applyFutureData(cached, fromCache: true);
    }

    try {
      final response = await _historyDayApi.getHistoryDayFuture();
      final body = response.data;
      final parsed = _extractFutureResponse(body);
      await _cacheFutureData(parsed);
      _applyFutureData(parsed);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = hasLocalData ? null : '加载失败';
      });
    }
  }

  Map<String, dynamic>? _readCachedFutureData() {
    final raw = LocalData.getString(_cacheKey);
    if (raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _cacheFutureData(Map<String, dynamic> data) async {
    await LocalData.setString(_cacheKey, jsonEncode(data));
    await LocalData.setString(
      _cacheUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  bool _applyFutureData(
    Map<String, dynamic> futureData, {
    bool fromCache = false,
  }) {
    final todayKey = _todayKey();
    final events = _extractEventsForDate(futureData, todayKey);
    final dayPayload = _extractDayPayload(futureData, todayKey);

    if (!mounted) return events.isNotEmpty || dayPayload.isNotEmpty;

    setState(() {
      _rawData = dayPayload;
      _events = events;
      _bannerIndex = 0;
      _loading = false;
      _error = null;
    });

    _resetBannerAutoPlay(events.length);

    return events.isNotEmpty || dayPayload.isNotEmpty || fromCache;
  }

  Map<String, dynamic> _extractFutureResponse(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map) {
        final nested = data['data'];
        if (nested is Map) {
          return Map<String, dynamic>.from(nested);
        }
        return Map<String, dynamic>.from(data);
      }
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _extractEventsForDate(
    Map<String, dynamic> data,
    String dateKey,
  ) {
    final value = data[dateKey];
    if (value is List) {
      return value
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _extractDayPayload(
    Map<String, dynamic> data,
    String dateKey,
  ) {
    final events = _extractEventsForDate(data, dateKey);
    return {'date': dateKey, 'title': '历史上的今天', 'events': events};
  }

  String _todayKey() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  String _pickString(
    Map<String, dynamic> data,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final key in keys) {
      final value = data[key];
      if (value != null) {
        final text = value.toString().trim();
        if (text.isNotEmpty) return text;
      }
    }
    return fallback;
  }

  String _eventTitle(Map<String, dynamic> item) {
    return _pickString(item, [
      'title',
      'name',
      'event',
      'headline',
    ], fallback: '历史事件');
  }

  String _eventSummary(Map<String, dynamic> item) {
    return _pickString(item, [
      'summary',
      'desc',
      'description',
      'shortComment',
      'comment',
      'review',
      'content',
      'detail',
    ], fallback: '暂无描述');
  }

  String _eventType(Map<String, dynamic> item) {
    return _pickString(item, [
      'type',
      'category',
      'tag',
      'group',
    ], fallback: '历史事件');
  }

  String _eventQuote(Map<String, dynamic> item) {
    return _pickString(item, [
      'quote',
      'summary',
      'comment',
      'review',
      'desc',
      'description',
    ], fallback: _eventSummary(item));
  }

  String _eventYear(Map<String, dynamic> item) {
    final directYear = _pickString(item, ['year']);
    if (directYear.isNotEmpty) return directYear;

    final dateText = _pickString(item, ['date', 'eventDate', 'time', 'day']);
    final m = RegExp(r'(\d{4})').firstMatch(dateText);
    if (m != null) {
      return m.group(1) ?? '--';
    }
    return '--';
  }

  List<Color> _gradientForType(String type) {
    if (type.contains('重大里程碑') || type.contains('里程碑')) {
      return const [Color(0xFF0E1A2F), Color(0xFF23395B), Color(0xFF2D4A6D)];
    }
    if (type.contains('社会变迁') || type.contains('社会')) {
      return const [Color(0xFF1A1325), Color(0xFF2D1E46), Color(0xFF40305F)];
    }
    if (type.contains('风云人物') || type.contains('人物')) {
      return const [Color(0xFF21130E), Color(0xFF3A2317), Color(0xFF5A3521)];
    }
    return const [Color(0xFF121826), Color(0xFF1E2A44), Color(0xFF2C3E63)];
  }

  void _resetBannerAutoPlay(int count) {
    _bannerTimer?.cancel();
    if (count <= 1) return;

    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerController.hasClients) return;
      final nextIndex = (_bannerIndex + 1) % count;
      _bannerController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Widget _buildHistoryBannerSection() {
    if (_events.isEmpty) {
      return _HistoryBanner(
        year: DateTime.now().year.toString(),
        title: '历史上的今天',
        type: '历史事件',
        quote: _pickString(_rawData, ['title', 'content'], fallback: '回响时刻'),
        gradientColors: _gradientForType('历史事件'),
        onTap: null,
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: _events.length,
            onPageChanged: (index) {
              setState(() {
                _bannerIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = _events[index];
              final title = _eventTitle(item);
              final type = _eventType(item);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _HistoryBanner(
                  year: _eventYear(item),
                  title: title,
                  type: type,
                  quote: _eventQuote(item),
                  gradientColors: _gradientForType(type),
                  onTap: () {
                    Navigator.of(context).push(
                      PageTransition(
                        type: PageTransitionType.rightToLeft,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        child: EchoDetailPage(title: title, data: item),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        if (_events.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_events.length, (index) {
              final active = index == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color:
                      active
                          ? const Color(0xFF1E2A44)
                          : const Color(0xFF1E2A44).withValues(alpha: 0.25),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Solar _todaySolar() {
    return Solar.fromDate(DateTime.now());
  }

  Lunar _todayLunar() {
    return _todaySolar().getLunar();
  }

  String _lunarValue() {
    final lunar = _todayLunar();
    return '${lunar.getMonthInChinese()}月${lunar.getDayInChinese()}';
  }

  String _lunarSubtitle() {
    final lunar = _todayLunar();
    final jieQi = lunar.getJieQi();
    final festivals = [
      ...lunar
          .getFestivals()
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty),
      ..._todaySolar()
          .getFestivals()
          .map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty),
    ];
    final parts = <String>[
      '${lunar.getYearInGanZhi()}年${lunar.getYearShengXiao()}',
    ];
    if (jieQi.trim().isNotEmpty) {
      parts.add(jieQi);
    }
    if (festivals.isNotEmpty) {
      parts.add(festivals.first);
    }
    return parts.join(' · ');
  }

  ({String title, String subtitle}) _nextHolidayInfo() {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    for (var i = 0; i <= 400; i++) {
      final date = start.add(Duration(days: i));
      final holiday = HolidayUtil.getHolidayByYmd(
        date.year,
        date.month,
        date.day,
      );
      if (holiday != null && !holiday.isWork()) {
        final name = holiday.getName().trim();
        if (name.isEmpty) {
          continue;
        }
        final subtitle =
            i == 0 ? '就是今天' : '${DateFormat('M月d日').format(date)} · 还有${i}天';
        return (title: name, subtitle: subtitle);
      }
    }
    return (title: '暂无节假日', subtitle: '未来一年内未检索到法定节假日');
  }

  String _weekText() {
    return DateFormat('M月d日 EEEE', 'zh_CN').format(DateTime.now());
  }

  String _cacheUpdatedAtText() {
    final raw = LocalData.getString(_cacheUpdatedAtKey);
    if (raw.trim().isEmpty) return '';

    try {
      final date = DateTime.parse(raw).toLocal();
      return '更新于 ${DateFormat('M月d日 HH:mm').format(date)}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final holidayInfo = _nextHolidayInfo();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHistoryBannerSection(),
                    if (_cacheUpdatedAtText().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          _cacheUpdatedAtText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _EchoInfoCard(
                            title: _weekText(),
                            value: _lunarValue(),
                            subtitle: _lunarSubtitle(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _EchoInfoCard(
                            title: '距离',
                            value: holidayInfo.title,
                            subtitle: holidayInfo.subtitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_loading)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: CircularProgressIndicator(color: primary),
                        ),
                      )
                    else if (_error != null)
                      _EchoStateCard(
                        text: _error!,
                        actionLabel: '重试',
                        onTap: _loadData,
                      )
                    else if (_events.isEmpty)
                      const _EchoStateCard(text: '今天还没有可展示的历史内容')
                    else
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: List.generate(_events.length, (index) {
                            final item = _events[index];
                            return _EchoTimelineItem(
                              title: _eventTitle(item),
                              summary: _eventSummary(item),
                              isLast: index == _events.length - 1,
                              onTap: () {
                                Navigator.of(context).push(
                                  PageTransition(
                                    type: PageTransitionType.rightToLeft,
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeOutCubic,
                                    child: EchoDetailPage(
                                      title: _eventTitle(item),
                                      data: item,
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ),
                      ),
                    const SizedBox(height: 96),
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

class _HistoryBanner extends StatelessWidget {
  const _HistoryBanner({
    required this.year,
    required this.title,
    required this.type,
    required this.quote,
    required this.gradientColors,
    required this.onTap,
  });

  final String year;
  final String title;
  final String type;
  final String quote;
  final List<Color> gradientColors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shownYear = year.trim().isEmpty ? '--' : year.trim();
    final shownQuote = quote.trim().isEmpty ? '时间会记住每一个改变。' : quote.trim();
    const radius = BorderRadius.all(Radius.circular(24));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 190,
          decoration: const BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Color(0x00000000),
                blurRadius: 14,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: 12,
                    bottom: -14,
                    child: Text(
                      shownYear,
                      style: TextStyle(
                        fontSize: 108,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.10),
                        letterSpacing: -2,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 28, 16, 56),
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 14,
                    right: 14,
                    bottom: 12,
                    child: Text(
                      '“$shownQuote”',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 13,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EchoInfoCard extends StatelessWidget {
  const _EchoInfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EchoTimelineItem extends StatelessWidget {
  const _EchoTimelineItem({
    required this.title,
    required this.summary,
    required this.isLast,
    required this.onTap,
  });

  final String title;
  final String summary;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              child: Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.24),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primary.withValues(alpha: 0.55),
                        width: 2,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 1.5,
                      height: 60,
                      color: primary.withValues(alpha: 0.22),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
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
}

class _EchoStateCard extends StatelessWidget {
  const _EchoStateCard({required this.text, this.actionLabel, this.onTap});

  final String text;
  final String? actionLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (actionLabel != null && onTap != null) ...[
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
