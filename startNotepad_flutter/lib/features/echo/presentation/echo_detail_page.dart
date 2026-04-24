import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EchoDetailPage extends StatelessWidget {
  const EchoDetailPage({super.key, required this.title, required this.data});

  final String title;
  final Map<String, dynamic> data;

  String _normalizeText(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  List<String> _dedupeTextList(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in values) {
      final text = raw.trim();
      if (text.isEmpty) continue;
      final key = _normalizeText(text);
      if (key.isEmpty || seen.contains(key)) continue;
      seen.add(key);
      result.add(text);
    }
    return result;
  }

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
    final primaryCandidates = _dedupeTextList([
      _pickString(['content']),
      _pickString(['detail']),
      _pickString(['description']),
      _pickString(['desc']),
      _pickString(['introduction']),
      _pickString(['summary']),
      _pickString(['remark']),
    ]);
    if (primaryCandidates.isNotEmpty) return primaryCandidates.first;

    const excludedKeys = {
      'id',
      'title',
      'name',
      'event',
      'headline',
      'date',
      'eventDate',
      'time',
      'year',
      'day',
      'type',
      'category',
      'tag',
      'source',
      'from',
      'author',
      'origin',
      'review',
      'comment',
      'shortComment',
    };

    final fallbackCandidates = _dedupeTextList(
      data.entries
          .where((entry) => !excludedKeys.contains(entry.key))
          .where((entry) => entry.value != null)
          .where((entry) => entry.value is! Map && entry.value is! List)
          .map((entry) => entry.value.toString().trim())
          .where(
            (text) =>
                text.isNotEmpty &&
                _normalizeText(text) != _normalizeText(title),
          )
          .toList(),
    );
    return fallbackCandidates.isNotEmpty ? fallbackCandidates.join('\n\n') : '';
  }

  String _reviewText() {
    final reviewCandidates = _dedupeTextList([
      _pickString(['review']),
      _pickString(['comment']),
      _pickString(['shortComment']),
      _pickString(['remark']),
      _pickString(['quote']),
    ]);
    if (reviewCandidates.isEmpty) return '';

    final content = _normalizeText(_contentText());
    for (final review in reviewCandidates) {
      if (_normalizeText(review) != content) {
        return review;
      }
    }
    return '';
  }

  String _eventTitleText() {
    final candidate = _pickString([
      'title',
      'name',
      'event',
      'headline',
    ], fallback: title);
    return candidate.isNotEmpty ? candidate : '历史事件';
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = _contentText();
    final review = _reviewText();
    final meta = _metaText();
    final eventTitle = _eventTitleText();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const Text(
                      '那年今日',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111111),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  eventTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withValues(alpha: 0.72),
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
                if (review.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDCE7FF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '短评',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3A5BA9),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          review,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: Color(0xFF44516B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
