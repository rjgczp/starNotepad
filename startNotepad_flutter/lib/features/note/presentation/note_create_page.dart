import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../../begin/login.dart';
import '../../../core/icons/iconfont_icons.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../tools/localData.dart';
import '../data/category_api.dart';
import '../data/category_offline_repository.dart';
import '../data/note_api.dart';
import '../data/note_offline_repository.dart';

class NoteCreatePage extends StatefulWidget {
  const NoteCreatePage({super.key, this.initialRecordedAt});

  final DateTime? initialRecordedAt;

  @override
  State<NoteCreatePage> createState() => _NoteCreatePageState();
}

class _NoteCreatePageState extends State<NoteCreatePage> {
  late final NoteApi _noteApi = NoteApi(ApiClient());
  late final NoteOfflineRepository _noteRepo = NoteOfflineRepository(
    NoteApi(ApiClient()),
  );
  late final CategoryOfflineRepository _categoryRepo =
      CategoryOfflineRepository(CategoryApi(ApiClient()));
  late final FlutterLocalNotificationsPlugin _notifications;

  // ── Form fields ──
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // ── Settings ──
  bool _isTop = false;
  bool _isHighlight = false;
  bool _isReminder = false;
  DateTime _recordedAt = DateTime.now();

  // ── Category ──
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;

  // ── Color ──
  String _selectedColorHex = '#FFFFFF';

  // ── Icon ──
  String _selectedIconCss = '';

  bool _submitting = false;
  bool _polishing = false;
  bool _showMoreSettings = false;

  @override
  void initState() {
    super.initState();
    _recordedAt = widget.initialRecordedAt ?? DateTime.now();
    _initializeNotifications();
    _loadCategories();
    _setDefaultColorAndIcon();
  }

  void _setDefaultColorAndIcon() {
    // 设置默认选择第一个颜色
    final colorItems = ThemeProvider().colors;
    if (colorItems.isNotEmpty) {
      final firstColor = colorItems.first;
      final hex =
          '#${(firstColor.color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
      _selectedColorHex = hex;
    }

    // 设置默认选择第一个图标
    final iconNames = IconfontIcons.byName.keys.toList();
    if (iconNames.isNotEmpty) {
      _selectedIconCss = iconNames.first;
    }
  }

  void _initializeNotifications() {
    _notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    _notifications.initialize(initSettings);
    tz.initializeTimeZones();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── Load categories ──
  Future<void> _loadCategories() async {
    try {
      final list = await _categoryRepo.loadAll();
      setState(() {
        _categories = list;
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  String _plainToHtml(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    return lines.map((l) => '<p>${l.trim()}</p>').join();
  }

  bool _isLoggedIn() {
    return LocalData.getString(ApiClient.tokenKey).trim().isNotEmpty;
  }

  Future<void> _showLoginRequiredDialog() async {
    await showDialog<void>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('请先登录'),
            content: const Text('AI 润色功能需要登录后使用。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => const Login()));
                },
                child: const Text('去登录'),
              ),
            ],
          ),
    );
  }

  Future<void> _polishNote() async {
    if (!_isLoggedIn()) {
      await _showLoginRequiredDialog();
      return;
    }

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    final text = [title, content].where((e) => e.isNotEmpty).join('\n');

    if (text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先输入标题或内容')));
      return;
    }
    if (_polishing || _submitting) return;

    setState(() => _polishing = true);

    try {
      final response = await _noteApi.polish(text: text);
      final body = response.data;

      if (body is! Map) {
        throw Exception('润色结果格式错误');
      }

      final map = Map<String, dynamic>.from(body);
      final code = map['code'];
      if (code != 200) {
        throw Exception(map['message']?.toString() ?? '润色失败');
      }

      final data = map['data'];
      if (data is! Map) {
        throw Exception('润色结果为空');
      }

      final result = Map<String, dynamic>.from(data);
      final polishedTitle = result['title']?.toString().trim() ?? '';
      final polishedContent = result['content']?.toString().trim() ?? '';

      if (polishedTitle.isEmpty && polishedContent.isEmpty) {
        throw Exception('润色结果为空');
      }

      if (polishedTitle.isNotEmpty) {
        _titleController.text = polishedTitle;
        _titleController.selection = TextSelection.fromPosition(
          TextPosition(offset: _titleController.text.length),
        );
      }

      if (polishedContent.isNotEmpty) {
        _contentController.text = polishedContent;
        _contentController.selection = TextSelection.fromPosition(
          TextPosition(offset: _contentController.text.length),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('AI润色完成')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('AI润色失败：$e')));
    } finally {
      if (mounted) {
        setState(() => _polishing = false);
      }
    }
  }

  // ── Submit ──
  Future<void> _submit() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入标题')));
      return;
    }
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final html = _plainToHtml(_contentController.text.trim());
      await _noteRepo.createLocalFirst(
        title: title,
        content: html,
        isTop: _isTop,
        categoryId: _selectedCategoryId,
        color: _selectedColorHex,
        icon: _selectedIconCss.isNotEmpty ? 'iconfont $_selectedIconCss' : null,
        isHighlight: _isHighlight,
        isReminder: _isReminder,
        recordedAt: _recordedAt,
      );

      if (!mounted) return;

      // 如果选择了提醒，询问是否添加系统日程
      if (_isReminder) {
        await _showAddCalendarDialog(title, html);
        if (!mounted) return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Calendar Integration ──
  Future<void> _showAddCalendarDialog(String title, String content) async {
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('添加提醒'),
            content: const Text('将在设定时间提醒？'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('添加'),
              ),
            ],
          ),
    );

    if (shouldAdd == true) {
      await _addToSystemCalendar(title, content);
    }
  }

  Future<void> _addToSystemCalendar(String title, String content) async {
    try {
      // 请求通知权限
      final hasPermission = await _requestNotificationPermission();
      if (!hasPermission) {
        if (!mounted) return;
        _showPermissionDeniedDialog();
        return;
      }

      // 构建提醒内容
      final plainContent = _htmlToPlainText(content);
      final description = plainContent.isNotEmpty ? plainContent : '无内容';

      // 安排系统通知
      await _scheduleNotification(title, description);

      if (!mounted) return;
      _showNotificationSuccessDialog(title, description);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('设置提醒失败: ${e.toString()}')));
    }
  }

  Future<bool> _requestNotificationPermission() async {
    // Android 13+ 需要请求通知权限
    if (Theme.of(context).platform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return true; // iOS 权限在初始化时已请求
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('需要通知权限'),
            content: const Text('为了及时提醒您查看记事，请开启通知权限。'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // 关闭对话框
                  Navigator.of(context).pop(true); // 返回首页
                },
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  openAppSettings();
                },
                child: const Text('去设置'),
              ),
            ],
          ),
    );
  }

  Future<void> _scheduleNotification(String title, String description) async {
    final scheduledTime = _recordedAt;

    // 如果时间已过，立即提醒
    if (scheduledTime.isBefore(DateTime.now())) {
      await _showImmediateNotification(title, description);
      return;
    }

    // 使用简单的延迟通知，避免精确闹钟权限问题
    const androidDetails = AndroidNotificationDetails(
      'note_reminders',
      '记事提醒',
      channelDescription: '记事本提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // 使用TZDateTime，但设置为非精确模式避免权限问题
    await _notifications.zonedSchedule(
      0,
      '记事提醒',
      '$title\n$description',
      tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> _showImmediateNotification(
    String title,
    String description,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'note_reminders',
      '记事提醒',
      channelDescription: '记事本提醒通知',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      '记事提醒',
      '$title\n$description',
      notificationDetails,
    );
  }

  void _showNotificationSuccessDialog(String title, String description) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('提醒已设置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('记事标题: $title'),
                const SizedBox(height: 8),
                Text('记事内容: $description'),
                const SizedBox(height: 8),
                Text('提醒时间: ${_recordedAt.toString().substring(0, 19)}'),
                const SizedBox(height: 16),
                const Text('系统将在指定时间发送通知提醒您'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // 关闭对话框
                  Navigator.of(context).pop(true); // 返回首页
                },
                child: const Text('知道了'),
              ),
            ],
          ),
    );
  }

  String _htmlToPlainText(String html) {
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

  // ─────────────────────────────── UI ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('新增'),
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
            label: const Text('保存'),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                _buildTitleField(),
                const SizedBox(height: 12),
                _buildAiPolishCard(cs),
                const SizedBox(height: 12),
                _buildEditorCard(cs),
                const SizedBox(height: 12),
                _buildMoreSettingsCard(cs),
              ],
            ),
          ),
          if (_polishing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildMoreSettingsCard(ColorScheme cs) {
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
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                _showMoreSettings = !_showMoreSettings;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: cs.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '更多设置',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _showMoreSettings ? '点击收起设置项' : '分类、时间、颜色、图标等',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withValues(alpha: 0.56),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _showMoreSettings ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _showMoreSettings
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  _buildSettingsCard(cs),
                  const SizedBox(height: 12),
                  _buildColorPicker(cs),
                  const SizedBox(height: 12),
                  _buildIconPicker(cs),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField() {
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
        controller: _titleController,
        textInputAction: TextInputAction.next,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: '输入标题…',
          prefixIcon: Icon(
            Icons.title_rounded,
            color: Colors.grey.shade400,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildAiPolishCard(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: cs.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 润色',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '根据当前标题和内容自动优化表达',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.56),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonal(
            onPressed: _polishing || _submitting ? null : _polishNote,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                _polishing
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('开始润色'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: Colors.black.withValues(alpha: 0.12),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'AI 正在润色…',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  // ── Settings card: toggles + category + date ──
  Widget _buildSettingsCard(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('分类'),
            const SizedBox(height: 8),
            _buildCategorySelector(cs),
            const Divider(height: 24),
            _buildSectionLabel('记录时间'),
            const SizedBox(height: 8),
            _buildDatePicker(cs),
            const Divider(height: 24),
            _buildToggleRow(cs),
          ],
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

  // ── Category selector ──
  Widget _buildCategorySelector(ColorScheme cs) {
    if (_loadingCategories) {
      return const SizedBox(
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_categories.isEmpty) {
      return Text(
        '暂无分类',
        style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      );
    }

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final id = cat['ID'] as int? ?? 0;
          final name = cat['name']?.toString() ?? '';
          final isSelected = _selectedCategoryId == id;
          final iconCss = cat['icon']?.toString() ?? '';
          final iconData = IconfontIcons.fromCssClass(iconCss);

          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (iconData != null) ...[
                  Icon(
                    iconData,
                    size: 14,
                    color: isSelected ? Colors.white : cs.primary,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(name),
              ],
            ),
            selected: isSelected,
            selectedColor: cs.primary,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
            onSelected: (_) {
              setState(() {
                _selectedCategoryId = isSelected ? null : id;
              });
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            side: BorderSide(
              color: isSelected ? cs.primary : Colors.grey.shade300,
            ),
          );
        },
      ),
    );
  }

  // ── Date picker ──
  Widget _buildDatePicker(ColorScheme cs) {
    final y = _recordedAt.year;
    final m = _recordedAt.month.toString().padLeft(2, '0');
    final d = _recordedAt.day.toString().padLeft(2, '0');
    final hh = _recordedAt.hour.toString().padLeft(2, '0');
    final mm = _recordedAt.minute.toString().padLeft(2, '0');

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _recordedAt,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (date == null || !mounted) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_recordedAt),
        );
        if (!mounted) return;

        setState(() {
          _recordedAt = DateTime(
            date.year,
            date.month,
            date.day,
            time?.hour ?? _recordedAt.hour,
            time?.minute ?? _recordedAt.minute,
          );
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              '$y-$m-$d  $hh:$mm',
              style: TextStyle(
                fontSize: 14,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.edit_calendar_rounded,
              size: 16,
              color: cs.primary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Toggles row ──
  Widget _buildToggleRow(ColorScheme cs) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _toggleChip(
          cs,
          '置顶',
          Icons.push_pin_outlined,
          _isTop,
          (v) => setState(() => _isTop = v),
        ),
        _toggleChip(
          cs,
          '高亮',
          Icons.highlight_outlined,
          _isHighlight,
          (v) => setState(() => _isHighlight = v),
        ),
        _toggleChip(
          cs,
          '提醒',
          Icons.notifications_outlined,
          _isReminder,
          (v) => setState(() => _isReminder = v),
        ),
      ],
    );
  }

  Widget _toggleChip(
    ColorScheme cs,
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: value ? Colors.white : cs.primary),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: value,
      selectedColor: cs.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: value ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: value ? cs.primary : Colors.grey.shade300),
    );
  }

  // ── Color picker (from API via ThemeProvider) ──
  Widget _buildColorPicker(ColorScheme cs) {
    final colorItems = ThemeProvider().colors;

    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionLabel('卡片颜色'),
            const SizedBox(height: 10),
            if (colorItems.isEmpty)
              Text(
                '加载中…',
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
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: item.color.withValues(
                                            alpha: 0.5,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
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

  // ── Icon picker ──
  Widget _buildIconPicker(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSectionLabel('图标'),
                const Spacer(),
                if (_selectedIconCss.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _selectedIconCss = ''),
                    child: Text(
                      '清除',
                      style: TextStyle(fontSize: 12, color: cs.primary),
                    ),
                  ),
              ],
            ),
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
                    if (_selectedIconCss.isNotEmpty) ...[
                      Icon(
                        IconfontIcons.byName[_selectedIconCss] ??
                            Icons.help_outline,
                        size: 22,
                        color: cs.primary,
                      ),
                      const Spacer(),
                    ] else
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
                              width: 40,
                              height: 40,
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

  // ── Content editor card ──
  Widget _buildEditorCard(ColorScheme cs) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: _buildSectionLabel('内容'),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 220, maxHeight: 320),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _contentController,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 15, height: 1.6),
                decoration: InputDecoration(
                  hintText: '写点什么…',
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
