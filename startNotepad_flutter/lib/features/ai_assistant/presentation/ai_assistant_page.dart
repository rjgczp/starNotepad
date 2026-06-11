import 'package:flutter/material.dart';

import '../data/agent_controller.dart';
import '../data/agent_models.dart';
import '../data/voice_input_service.dart';
import 'widgets/agent_message_bubble.dart';

/// AI Agent 助手页：对话式界面，支持语音 / 一句话指令，
/// AI 把指令翻译成可预览的操作卡片，用户确认后执行（整理/重构/导出笔记）。
class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key, this.onOpenSettings, this.onOpenProfile});

  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenProfile;

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final AgentController _controller = AgentController();
  final VoiceInputService _voice = VoiceInputService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 预留底部悬浮导航栏的高度，避免输入框被遮挡
  static const double _bottomNavReserve = 92;

  final List<AgentMessage> _messages = [];
  bool _sending = false;
  bool _listening = false;

  static const List<String> _suggestions = [
    '把今天的笔记整理成一篇日记',
    '把零散待办合并成一条清单',
    '给我的笔记按主题分类',
    '导出本周笔记为 Markdown',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(
      AgentMessage(
        role: AgentMessageRole.assistant,
        text: '你好，我是星记事 AI 助手。用一句话或语音告诉我，我可以帮你整理、重构、合并、分类或导出笔记。',
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final instruction = text.trim();
    if (instruction.isEmpty || _sending) return;

    setState(() {
      _messages.add(AgentMessage(role: AgentMessageRole.user, text: instruction));
      _sending = true;
      _inputController.clear();
    });
    _scrollToBottom();

    try {
      final reply = await _controller.send(instruction);
      if (!mounted) return;
      setState(() => _messages.add(reply));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          AgentMessage(
            role: AgentMessageRole.assistant,
            text: '出错了：${e.toString().replaceFirst('Exception: ', '')}',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _toggleVoice() async {
    if (_listening) {
      await _voice.stop();
      if (mounted) setState(() => _listening = false);
      return;
    }

    try {
      final ok = await _voice.init();
      if (!ok) {
        _showSnack('语音功能不可用，请检查麦克风权限');
        return;
      }
      setState(() => _listening = true);
      await _voice.start(
        onResult: (text, isFinal) {
          if (!mounted) return;
          setState(() => _inputController.text = text);
          if (isFinal) {
            setState(() => _listening = false);
          }
        },
      );
    } catch (e) {
      if (mounted) setState(() => _listening = false);
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _runAction(AgentAction action) async {
    setState(() => action.status = AgentActionStatus.pending);
    try {
      await _controller.executeAction(action);
      if (!mounted) return;
      setState(() => action.status = AgentActionStatus.done);
      _showSnack('${action.summaryTitle}已完成');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        action.status = AgentActionStatus.failed;
        action.errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnack('执行失败：${action.errorMessage}');
    }
  }

  void _ignoreAction(AgentAction action) {
    setState(() => action.status = AgentActionStatus.ignored);
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, _bottomNavReserve + 8),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(cs),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return AgentMessageBubble(
                    message: _messages[index],
                    onRunAction: _runAction,
                    onIgnoreAction: _ignoreAction,
                  );
                },
              ),
            ),
            if (_messages.length <= 1) _buildSuggestions(cs),
            _buildInputBar(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [cs.primary, cs.primary.withValues(alpha: 0.65)],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI 助手',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '一句话整理 · 重构 · 导出笔记',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (widget.onOpenProfile != null)
            _circleAction(Icons.manage_accounts_outlined, widget.onOpenProfile!, cs),
          if (widget.onOpenSettings != null)
            _circleAction(Icons.settings_outlined, widget.onOpenSettings!, cs),
        ],
      ),
    );
  }

  Widget _circleAction(IconData icon, VoidCallback onTap, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: Colors.black.withValues(alpha: 0.6)),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions(ColorScheme cs) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _suggestions.map((s) {
            return Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _sending ? null : () => _send(s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
                  ),
                  child: Text(
                    s,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        _bottomNavReserve + MediaQuery.of(context).viewInsets.bottom * 0,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(color: Color(0x12000000), blurRadius: 18, offset: Offset(0, 6)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _sending ? null : _toggleVoice,
              icon: Icon(
                _listening ? Icons.mic : Icons.mic_none_rounded,
                color: _listening ? Colors.red : cs.primary,
              ),
              tooltip: _listening ? '停止录音' : '语音输入',
            ),
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: _send,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: _listening ? '正在聆听…' : '说说要我帮你做什么',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _sending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary, cs.primary.withValues(alpha: 0.7)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _send(_inputController.text),
                      icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
