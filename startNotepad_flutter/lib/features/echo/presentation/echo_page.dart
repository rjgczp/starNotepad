import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
    _historyDayApi = HistoryDayApi(ApiClient());
    _loadData();
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
      _loading = false;
      _error = null;
    });

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

  String _headerTitle() {
    final firstEvent = _events.isNotEmpty ? _events.first : <String, dynamic>{};
    final header = _pickString(_rawData, [
      'title',
      'bannerTitle',
      'sentence',
      'content',
      'intro',
    ]);
    if (header.isNotEmpty && header != '历史上的今天') {
      return header;
    }
    return _pickString(firstEvent, [
      'quote',
      'summary',
      'title',
    ], fallback: '历史上的今天');
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '回响',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
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
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Container(
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary.withValues(alpha: 0.22),
                                primary.withValues(alpha: 0.08),
                              ],
                            ),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.08),
                            ),
                          ),
                          padding: const EdgeInsets.all(18),
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _headerTitle(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.45,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
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
                                        duration: const Duration(
                                          milliseconds: 280,
                                        ),
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
                ),
              ),
            ],
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
