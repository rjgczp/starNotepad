import 'package:get/get.dart';
import '../controllers/note_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NoteController(), permanent: true);
  }
}
