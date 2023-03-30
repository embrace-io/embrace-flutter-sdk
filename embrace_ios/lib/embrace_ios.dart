import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/method_channel_embrace.dart';

/// The iOS implementation of [EmbracePlatform].
class EmbraceIOS extends MethodChannelEmbrace {
  /// Registers this class as the default instance of [EmbracePlatform]
  static void registerWith() {
    EmbracePlatform.instance = EmbraceIOS();
  }
  // override classes here if needed
}
