import 'package:flutter_tts/flutter_tts.dart';

/// 发音服务：调用系统 TTS，离线可用，不占包体
class TtsService {
  final FlutterTts _tts = FlutterTts();
  String _accent = 'US';
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    _ready = true;
  }

  set accent(String v) {
    _accent = v;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _init();
    await _tts.stop();
    await _tts.setLanguage(_accent == 'UK' ? 'en-GB' : 'en-US');
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}

/// 全局单例，页面里直接 globalTts.speak('word') 即可
final TtsService globalTts = TtsService();
