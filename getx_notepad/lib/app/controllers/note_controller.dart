import 'package:get/get.dart';
import '../models/note_model.dart';
import '../services/database_service.dart';

class NoteController extends GetxController {
  final DatabaseService _dbService = DatabaseService.instance;

  final RxList<NoteModel> notes = <NoteModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotes();
  }

  Future<void> loadNotes() async {
    isLoading.value = true;
    try {
      if (searchQuery.value.isEmpty) {
        notes.value = await _dbService.getAllNotes();
      } else {
        notes.value = await _dbService.searchNotes(searchQuery.value);
      }
    } catch (e) {
      Get.snackbar('错误', '加载笔记失败: $e', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addNote(String title, String content) async {
    final now = DateTime.now();
    final note = NoteModel(
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
    await _dbService.insertNote(note);
    await loadNotes();
    Get.snackbar('成功', '笔记已添加', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> updateNote(NoteModel note, String title, String content) async {
    final updated = note.copyWith(
      title: title,
      content: content,
      updatedAt: DateTime.now(),
    );
    await _dbService.updateNote(updated);
    await loadNotes();
    Get.snackbar('成功', '笔记已更新', snackPosition: SnackPosition.BOTTOM);
  }

  Future<void> deleteNote(int id) async {
    await _dbService.deleteNote(id);
    await loadNotes();
    Get.snackbar('成功', '笔记已删除', snackPosition: SnackPosition.BOTTOM);
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    loadNotes();
  }

  String getPreviewContent(String content, {int maxLength = 80}) {
    final cleaned = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleaned.length <= maxLength) return cleaned;
    return '${cleaned.substring(0, maxLength)}...';
  }

  String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);

    final diff = today.difference(dateDay).inDays;
    if (diff == 0) {
      return '今天 ${_pad(date.hour)}:${_pad(date.minute)}';
    } else if (diff == 1) {
      return '昨天 ${_pad(date.hour)}:${_pad(date.minute)}';
    } else if (diff < 7) {
      return '$diff天前';
    } else {
      return '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
