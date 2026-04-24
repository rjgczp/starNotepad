import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_instance.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key, this.onOpenSettings, this.onOpenProfile});

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenProfile;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final AppDatabase _db = DbInstance.db;
  bool _projectExpanded = false;
  bool _heatmapLoading = true;
  int _maxDailyCount = 0;
  List<int> _monthlyHeatmapCounts = const [];
  DateTime _currentMonth = DateTime.now();

  static const _projectUrl = 'https://github.com/rjgczp/starNotepad';
  @override
  void initState() {
    super.initState();
    _loadMonthlyHeatmap();
  }

  Future<void> _loadMonthlyHeatmap() async {
    final month = DateTime.now();
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final counts = List<int>.filled(daysInMonth, 0);

    try {
      final rows = await _db.getActiveNotes();
      for (final note in rows) {
        final day = note.recordedAt ?? note.updatedAt ?? note.updatedAtLocal;
        if (day.isBefore(firstDay) || day.isAfter(lastDay)) continue;
        counts[day.day - 1] += 1;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _currentMonth = month;
      _monthlyHeatmapCounts = counts;
      _maxDailyCount =
          counts.isEmpty ? 0 : counts.reduce((a, b) => a > b ? a : b);
      _heatmapLoading = false;
    });
  }

  int _countToLevel(int count) {
    if (count <= 0 || _maxDailyCount <= 0) return 0;
    final ratio = count / _maxDailyCount;
    if (ratio >= 0.75) return 3;
    if (ratio >= 0.4) return 2;
    return 1;
  }

  Future<void> _openGithub() async {
    final uri = Uri.parse(_projectUrl);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (ok || !mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('无法打开 GitHub 链接')));
  }

  Color _footprintColor(int level) {
    switch (level) {
      case 3:
        return const Color(0xFF1F8D49);
      case 2:
        return const Color(0xFF5DBB63);
      case 1:
        return const Color(0xFFA7DFA8);
      default:
        return const Color(0xFFEAF3EA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, 96 + bottomInset),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF7FBFF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCEBFF)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: Color(0xFF356BC7)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '今日一言 · 每日更新，提供文艺慰藉',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF234A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFEE6A8), Color(0xFFFFC67C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.casino_rounded,
                      size: 24,
                      color: Color(0xFF8A4B08),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '灵感转盘',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '圆形小图标入口，点击进入独立抽屉触发灵感',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFF7B7F86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '进入',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6C7481),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFDCE8FF)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Color(0xFF355FB6)),
                      SizedBox(width: 8),
                      Text(
                        '专注时刻',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1F3E7D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(seconds: 2),
                        builder: (context, value, _) {
                          return SizedBox(
                            width: 56,
                            height: 56,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 5,
                                  color: const Color(0xFF5A8BEB),
                                  backgroundColor: const Color(0xFFDFE9FF),
                                ),
                                const Text(
                                  '25',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF355FB6),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '带倒计时动画的卡片，快速启动计时，状态同步至首页',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: Color(0xFF5F6A7A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.public_rounded, color: Color(0xFF2F6B44)),
                      SizedBox(width: 8),
                      Text(
                        '星际足迹',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_currentMonth.month}月记录热力图',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B7F86),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_heatmapLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 6),
                      ),
                    )
                  else
                    _buildMonthlyHeatmap(),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
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
              child: Column(
                children: [
                  _MoreItemTile(
                    icon: Icons.settings_outlined,
                    title: '常用设置',
                    subtitle: '主题、同步、版本与偏好配置',
                    onTap: widget.onOpenSettings,
                  ),
                  const Divider(height: 1),
                  _MoreItemTile(
                    icon: Icons.manage_accounts_outlined,
                    title: '个人资料',
                    subtitle: '头像、昵称、签名与账户信息',
                    onTap: widget.onOpenProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      setState(() {
                        _projectExpanded = !_projectExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '项目地址',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _projectExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 220),
                    crossFadeState:
                        _projectExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: const SizedBox.shrink(),
                    secondChild: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText(
                            _projectUrl,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            onPressed: _openGithub,
                            icon: const Icon(
                              Icons.open_in_new_rounded,
                              size: 18,
                            ),
                            label: const Text('一键直达 GitHub 项目地址'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyHeatmap() {
    final daysInMonth = _monthlyHeatmapCounts.length;
    final cells = List<int>.generate(daysInMonth, (index) => index + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children:
            cells.map((day) {
              final count = _monthlyHeatmapCounts[day - 1];
              final level = _countToLevel(count);
              return Tooltip(
                message: '$day日 · $count 条记录',
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: _footprintColor(level),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

class _MoreItemTile extends StatelessWidget {
  const _MoreItemTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: const Color(0xFF52627A)),
            ),
            const SizedBox(width: 10),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B7F86),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A1AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
