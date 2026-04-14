import 'package:flutter/material.dart';
// 暂时移除 flutter_screenutil，因为它导致缩放问题
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// 需要在 pubspec.yaml 中添加: table_calendar: ^3.0.9
// import 'package:table_calendar/table_calendar.dart';
import 'package:startnotepad_flutter/core/db/app_database.dart';
import 'package:startnotepad_flutter/core/db/db_instance.dart';
import 'package:startnotepad_flutter/core/network/api_client.dart';
import 'package:startnotepad_flutter/core/icons/iconfont_widget.dart';
import 'package:startnotepad_flutter/features/note/data/note_api.dart';
import 'package:startnotepad_flutter/features/note/data/note_statistics_api.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_create_page.dart';
import 'package:startnotepad_flutter/features/note/presentation/note_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:page_transition/page_transition.dart';
import 'package:timelines_plus/timelines_plus.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  late final NoteStatisticsApi _statisticsApi;
  late final NoteApi _noteApi;
  final AppDatabase _db = DbInstance.db;
  Map<String, List<String>> _statisticsData = {};
  List<Map<String, dynamic>> _selectedDayNotes = [];
  DateTime _currentMonth = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  bool _isLoading = false;
  bool _isTimelineLoading = false;

  @override
  void initState() {
    super.initState();
    // 初始化中文日期格式
    initializeDateFormatting('zh_CN');
    _statisticsApi = NoteStatisticsApi(ApiClient());
    _noteApi = NoteApi(ApiClient());
    _loadStatistics();
    _loadSelectedDayNotes();
  }

  /// 加载统计数据
  Future<void> _loadStatistics() async {
    if (!mounted) return;

    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );

    setState(() {
      _isLoading = true;
    });

    var loadedRemotely = false;

    try {
      final response = await _statisticsApi.getStatistics(
        startDate: DateFormat('yyyy-MM-dd').format(firstDay),
        endDate: DateFormat('yyyy-MM-dd').format(lastDay),
      );

      final body = response.data;
      if (body['code'] == 200) {
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final formattedData = _formatRemoteStatistics(data);
          if (mounted) {
            setState(() {
              _statisticsData = formattedData;
              _isLoading = false;
            });
          }
          loadedRemotely = true;
        }
      }
    } catch (e) {
      print('加载统计数据失败: $e');
    }

    if (loadedRemotely) {
      return;
    }

    try {
      final localData = await _loadLocalStatistics(firstDay, lastDay);
      if (mounted) {
        setState(() {
          _statisticsData = localData;
        });
      }
    } catch (e) {
      print('加载本地统计数据失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadSelectedDayNotes() async {
    if (!mounted) return;

    setState(() {
      _isTimelineLoading = true;
    });

    try {
      final response = await _noteApi.calendar(
        date: DateFormat('yyyy-MM-dd').format(_selectedDay),
      );
      final body = response.data;
      if (body['code'] == 200) {
        final data = body['data'];
        if (data is List) {
          final notes =
              data
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
          if (mounted) {
            setState(() {
              _selectedDayNotes = notes;
              _isTimelineLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      print('加载日历明细失败: $e');
    }

    try {
      final local = await _loadLocalNotesForDay(_selectedDay);
      if (mounted) {
        setState(() {
          _selectedDayNotes = local;
        });
      }
    } catch (e) {
      print('加载本地日历明细失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isTimelineLoading = false;
        });
      }
    }
  }

  /// 获取指定日期的图标列表（最多3个）
  List<String> _getIconsForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    final icons = _statisticsData[dateStr] ?? [];
    return icons.take(3).toList();
  }

  Map<String, List<String>> _formatRemoteStatistics(Map<String, dynamic> data) {
    final Map<String, List<String>> formattedData = {};
    data.forEach((key, value) {
      final dateStr = key.split('T')[0];
      final icons = List<String>.from(value);
      formattedData[dateStr] = icons;
    });
    return formattedData;
  }

  Future<Map<String, List<String>>> _loadLocalStatistics(
    DateTime firstDay,
    DateTime lastDay,
  ) async {
    final rows = await _db.getActiveNotes();
    final result = <String, List<String>>{};

    for (final note in rows) {
      final day = _resolveDiaryDate(note);
      if (day == null) continue;
      if (day.isBefore(firstDay) || day.isAfter(lastDay)) continue;

      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final iconName = (note.icon ?? '').trim();
      if (iconName.isEmpty) continue;

      result.putIfAbsent(dateStr, () => <String>[]).add(iconName);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _loadLocalNotesForDay(DateTime day) async {
    final rows = await _db.getActiveNotes();
    final result = <Map<String, dynamic>>[];

    for (final note in rows) {
      final targetDay = _resolveDiaryDate(note);
      if (targetDay == null || !isSameDay(targetDay, day)) continue;

      result.add(<String, dynamic>{
        'id': note.remoteId ?? note.localId,
        'localId': note.localId,
        'remoteId': note.remoteId,
        'title': note.title,
        'content': note.content,
        'icon': note.icon,
        'color': note.color,
        'isTop': note.isTop,
        'isHighlight': note.isHighlight,
        'isReminder': note.isReminder,
        'categoryID': note.categoryId,
        'recordedAt': note.recordedAt?.toIso8601String(),
        'createdAt':
            (note.recordedAt ?? note.updatedAtRemote ?? note.updatedAtLocal)
                .toIso8601String(),
        'updatedAt':
            (note.updatedAtRemote ?? note.updatedAtLocal).toIso8601String(),
      });
    }

    result.sort((a, b) {
      final aDate = _parseDate(a['createdAt'] ?? a['recordedAt']);
      final bDate = _parseDate(b['createdAt'] ?? b['recordedAt']);
      if (aDate == null || bDate == null) return 0;
      return aDate.compareTo(bDate);
    });

    return result;
  }

  DateTime? _resolveDiaryDate(Note note) {
    return note.recordedAt ?? note.updatedAt ?? note.updatedAtLocal;
  }

  /// 获取月份的天数
  int _getDaysInMonth(DateTime month) {
    return DateTime(month.year, month.month + 1, 0).day;
  }

  /// 获取月份第一天是星期几
  int _getFirstDayOfWeek(DateTime month) {
    return DateTime(month.year, month.month, 1).weekday;
  }

  /// 切换到上一个月
  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
    _loadStatistics();
  }

  /// 切换到下一个月
  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
    _loadStatistics();
  }

  /// 点击日期
  void _onDaySelected(DateTime day) {
    setState(() {
      _selectedDay = day;
    });
    _loadSelectedDayNotes();
  }

  Future<void> _openCreateForSelectedDay() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NoteCreatePage(initialRecordedAt: _selectedDay),
      ),
    );
    if (created == true && mounted) {
      await _loadStatistics();
      await _loadSelectedDayNotes();
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value.replaceAll(' ', 'T'));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = Theme.of(context).primaryColor;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
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
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('yyyy年MM月', 'zh_CN').format(_currentMonth),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF181818),
                          ),
                        ),
                      ),
                      _buildMonthAction(
                        icon: Icons.chevron_left,
                        onTap: _previousMonth,
                      ),
                      const SizedBox(width: 6),
                      _buildMonthAction(
                        icon: Icons.chevron_right,
                        onTap: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildWeekDays(),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(color: primaryColor),
                      ),
                    )
                  else
                    _buildCalendarGrid(),
                  const SizedBox(height: 6),
                  _buildTimelineSection(colorScheme, primaryColor),
                  SizedBox(height: 72 + bottomSafeArea),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF8F867D)),
        ),
      ),
    );
  }

  Widget _buildWeekDays() {
    const weekDays = ['一', '二', '三', '四', '五', '六', '日'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children:
            weekDays
                .map(
                  (day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF55504B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = _getDaysInMonth(_currentMonth);
    final firstDayOfWeek = _getFirstDayOfWeek(_currentMonth);
    final totalCells = (daysInMonth + firstDayOfWeek - 1);
    final rows = (totalCells / 7).ceil();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.88,
        ),
        itemCount: rows * 7,
        itemBuilder: (context, index) {
          final dayNumber = index - firstDayOfWeek + 2;
          final isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;

          if (!isValidDay) {
            return const SizedBox.shrink();
          }

          final day = DateTime(
            _currentMonth.year,
            _currentMonth.month,
            dayNumber,
          );
          final icons = _getIconsForDay(day);
          final isSelected = isSameDay(day, _selectedDay);
          final isToday = isSameDay(day, DateTime.now());

          return _buildDayCell(day, icons, isSelected, isToday);
        },
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day,
    List<String> icons,
    bool isSelected,
    bool isToday,
  ) {
    final primaryColor = Theme.of(context).primaryColor;
    final hasIcons = icons.isNotEmpty;
    final iconColor =
        isSelected
            ? Colors.white.withValues(alpha: 0.95)
            : Colors.black.withValues(alpha: 0.8);
    final textColor =
        isSelected
            ? Colors.white
            : isToday
            ? primaryColor
            : Colors.black87;

    return GestureDetector(
      onTap: () => _onDaySelected(day),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? primaryColor
                  : hasIcons
                  ? _buildSoftDayColor(day)
                  : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(18),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.40),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasIcons) ...[
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...icons.take(2).toList().asMap().entries.map((entry) {
                      final index = entry.key;
                      final icon = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(left: index == 0 ? 0 : 1),
                        child: IconfontWidget(
                          iconName: icon,
                          size: 10,
                          color: iconColor,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _buildSoftDayColor(DateTime day) {
    const colors = [
      Color(0xFFFFF3E0), // 浅橙色
      Color(0xFFE8F5E9), // 浅绿色
      Color(0xFFE3F2FD), // 浅蓝色
      Color(0xFFFCE4EC), // 浅粉色
      Color(0xFFF3E5F5), // 浅紫色
      Color(0xFFE0F2F1), // 浅青色
      Color(0xFFFFF8E1), // 浅黄色
    ];
    return colors[day.day % colors.length];
  }

  Widget _buildTimelineSection(ColorScheme colorScheme, Color primaryColor) {
    final dateLabel = DateFormat('MM月dd日', 'zh_CN').format(_selectedDay);
    final hasNotes = _selectedDayNotes.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$dateLabel ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF181818),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasNotes ? '按时间排序' : '当天还没有记事',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateForSelectedDay,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('新增'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isTimelineLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: primaryColor,
                ),
              ),
            )
          else if (!hasNotes)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Text(
                '暂无记录',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            )
          else
            FixedTimeline.tileBuilder(
              theme: TimelineThemeData(
                nodePosition: 0.04,
                indicatorPosition: 0.5,
                connectorTheme: ConnectorThemeData(
                  color: primaryColor.withValues(alpha: 0.35),
                  thickness: 2.2,
                ),
              ),
              builder: TimelineTileBuilder.connected(
                connectionDirection: ConnectionDirection.before,
                itemCount: _selectedDayNotes.length,
                contentsAlign: ContentsAlign.basic,
                contentsBuilder:
                    (context, index) => _buildTimelineCard(
                      _selectedDayNotes[index],
                      primaryColor,
                    ),
                indicatorBuilder: (context, index) {
                  final iconStr =
                      _selectedDayNotes[index]['icon']?.toString() ?? '';
                  final hasIcon = iconStr.trim().isNotEmpty;
                  return OutlinedDotIndicator(
                    size: 16,
                    borderWidth: 2.4,
                    color: primaryColor,
                    backgroundColor:
                        hasIcon
                            ? primaryColor.withValues(alpha: 0.18)
                            : Colors.white,
                  );
                },
                connectorBuilder: (context, index, connectorType) {
                  return SolidLineConnector(
                    color: primaryColor.withValues(alpha: 0.35),
                    thickness: 2.2,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineTime(Map<String, dynamic> item, Color primaryColor) {
    final dt = _parseDate(
      item['createdAt'] ?? item['recordedAt'] ?? item['updatedAt'],
    );
    final timeText = dt != null ? DateFormat('HH:mm').format(dt) : '--:--';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Text(
        timeText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: primaryColor,
        ),
      ),
    );
  }

  Widget _buildTimelineCard(Map<String, dynamic> item, Color primaryColor) {
    final iconStr = item['icon']?.toString() ?? '';
    final hasIcon = iconStr.trim().isNotEmpty;
    final bgColor =
        Color.lerp(primaryColor, Colors.white, 0.78) ?? Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(context).push<void>(
          PageTransition(
            type: PageTransitionType.rightToLeft,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: NoteDetailPage(note: item),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 18, bottom: 16),
        child: Material(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimelineTime(item, primaryColor),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color:
                            hasIcon
                                ? Colors.white.withValues(alpha: 0.76)
                                : Colors.white.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          hasIcon
                              ? IconfontWidget(
                                iconName: iconStr,
                                size: 17,
                                color: primaryColor,
                              )
                              : Icon(
                                Icons.horizontal_rule_rounded,
                                size: 18,
                                color: primaryColor.withValues(alpha: 0.55),
                              ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['title']?.toString().trim().isNotEmpty == true
                            ? item['title'].toString()
                            : '未命名记事',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: primaryColor.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 检查两个日期是否是同一天
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}
