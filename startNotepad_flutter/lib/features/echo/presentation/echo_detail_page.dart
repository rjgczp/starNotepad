import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EchoDetailPage extends StatelessWidget {
  const EchoDetailPage({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  String _pickString(List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  String _contentText() {
    final primary = _pickString([
      'content',
      'description',
      'desc',
      'summary',
      'detail',
      'introduction',
      'remark',
    ]);
    if (primary.isNotEmpty) return primary;

    final fallback =
        data.entries
            .where((entry) => entry.value != null)
            .where((entry) => entry.value is! Map && entry.value is! List)
            .map((entry) => entry.value.toString().trim())
            .where((text) => text.isNotEmpty && text != title)
            .toList();
    return fallback.isNotEmpty ? fallback.join('\n\n') : '';
  }

  String _metaText() {
    final pieces = <String>[];

    final dateText = _pickString(['date', 'eventDate', 'time', 'year', 'day']);
    if (dateText.isNotEmpty) {
      pieces.add(dateText);
    }

    final sourceText = _pickString(['source', 'from', 'author', 'origin']);
    if (sourceText.isNotEmpty) {
      pieces.add(sourceText);
    }

    final categoryText = _pickString(['type', 'category', 'tag']);
    if (categoryText.isNotEmpty) {
      pieces.add(categoryText);
    }

    return pieces.join('  ·  ');
  }

  String _summaryText() {
    final summary = _pickString(['summary', 'desc', 'description', 'subtitle']);
    final content = _contentText();
    if (summary.isNotEmpty && summary != content) {
      return summary;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = _contentText();
    final summary = _summaryText();
    final meta = _metaText();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  title.isNotEmpty ? title : '历史事件',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111111),
                    height: 1.25,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    meta,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    summary,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Expanded(
                  child: Container(
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
                    child: SingleChildScrollView(
                      child:
                          content.isNotEmpty
                              ? SelectableText(
                                content,
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
                                        Icons.history_edu_outlined,
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
