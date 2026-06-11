import 'package:flutter/material.dart';

import '../../data/agent_models.dart';

/// 单条对话气泡，AI 消息下方渲染可执行的操作卡片。
class AgentMessageBubble extends StatelessWidget {
  const AgentMessageBubble({
    super.key,
    required this.message,
    required this.onRunAction,
    required this.onIgnoreAction,
  });

  final AgentMessage message;
  final void Function(AgentAction action) onRunAction;
  final void Function(AgentAction action) onIgnoreAction;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF356BC7) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
        ...message.actions.map(
          (action) => _ActionCard(
            action: action,
            onRun: () => onRunAction(action),
            onIgnore: () => onIgnoreAction(action),
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.onRun,
    required this.onIgnore,
  });

  final AgentAction action;
  final VoidCallback onRun;
  final VoidCallback onIgnore;

  IconData get _icon {
    switch (action.type) {
      case AgentActionType.createNote:
        return Icons.note_add_outlined;
      case AgentActionType.updateNote:
        return Icons.edit_outlined;
      case AgentActionType.mergeNotes:
        return Icons.merge_type_rounded;
      case AgentActionType.categorize:
        return Icons.folder_outlined;
      case AgentActionType.export:
        return Icons.ios_share_rounded;
      case AgentActionType.unknown:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = action.status == AgentActionStatus.done;
    final ignored = action.status == AgentActionStatus.ignored;
    final failed = action.status == AgentActionStatus.failed;

    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 4),
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.82,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_icon, size: 18, color: const Color(0xFF356BC7)),
              const SizedBox(width: 6),
              Text(
                action.summaryTitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F3E7D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            action.summaryDetail,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: Color(0xFF55606F),
            ),
          ),
          const SizedBox(height: 8),
          _buildFooter(done, ignored, failed),
        ],
      ),
    );
  }

  Widget _buildFooter(bool done, bool ignored, bool failed) {
    if (done) {
      return const Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF1F8D49)),
          SizedBox(width: 4),
          Text(
            '已执行',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF1F8D49),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }
    if (ignored) {
      return const Text(
        '已忽略',
        style: TextStyle(fontSize: 12, color: Color(0xFF98A1AF)),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (failed)
          Expanded(
            child: Text(
              action.errorMessage ?? '执行失败',
              style: const TextStyle(fontSize: 11.5, color: Colors.red),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        TextButton(
          onPressed: onIgnore,
          child: const Text('忽略', style: TextStyle(fontSize: 12)),
        ),
        const SizedBox(width: 4),
        FilledButton(
          onPressed: onRun,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Text(failed ? '重试' : '确认执行', style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
