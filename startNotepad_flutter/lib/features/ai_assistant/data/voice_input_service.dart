import 'package:speech_to_text/speech_to_text.dart';

/// 语音输入服务：封装 speech_to_text，提供初始化、开始/停止识别。
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _available = false;

  bool get isListening => _speech.isListening;

  /// 初始化语音引擎，返回是否可用。
  Future<bool> init() async {
    if (_available) return true;
    _available = await _speech.initialize(
      onError: (e) {},
      onStatus: (s) {},
    );
    return _available;
  }

  /// 开始监听，识别到的文字通过 onResult 回调实时返回。
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    if (!_available) {
      final ok = await init();
      if (!ok) {
        throw Exception('语音功能不可用，请检查麦克风权限');
      }
    }
    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        localeId: 'zh_CN',
      ),
    );

  }

  Future<void> stop() async {
    await _speech.stop();
  }

  Future<void> cancel() async {
    await _speech.cancel();
  }
}
