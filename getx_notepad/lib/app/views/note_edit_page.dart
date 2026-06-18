import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/note_controller.dart';

class NoteEditPage extends StatelessWidget {
  final dynamic note;

  const NoteEditPage({super.key, this.note});

  @override
  Widget build(BuildContext context) {
    final NoteController controller = Get.find();
    final isEditing = note != null;

    final titleController = TextEditingController(
      text: isEditing ? note.title : '',
    );
    final contentController = TextEditingController(
      text: isEditing ? note.content : '',
    );

    Future<void> save() async {
      final title = titleController.text.trim();
      final content = contentController.text.trim();

      if (title.isEmpty && content.isEmpty) {
        Get.snackbar('提示', '标题和内容不能同时为空', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      if (isEditing) {
        await controller.updateNote(note, title, content);
      } else {
        await controller.addNote(title, content);
      }
      Get.back();
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          titleController.dispose();
          contentController.dispose();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditing ? '编辑笔记' : '新建笔记'),
          actions: [
            TextButton.icon(
              onPressed: save,
              icon: const Icon(Icons.check),
              label: const Text('保存'),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextField(
                controller: titleController,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  hintText: '输入标题...',
                  border: InputBorder.none,
                ),
                autofocus: !isEditing,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 4),
              // Divider
              Divider(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              // Content field
              Expanded(
                child: TextField(
                  controller: contentController,
                  style: const TextStyle(fontSize: 16, height: 1.6),
                  decoration: InputDecoration(
                    hintText: '开始记录你的想法...',
                    hintStyle: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                  ),
                  autofocus: isEditing,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
