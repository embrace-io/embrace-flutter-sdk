import 'package:embrace_platform_interface/embrace_platform_interface.dart';
import 'package:embrace_platform_interface/method_channel_embrace.dart';

/// The Android implementation of [EmbracePlatform].
class EmbraceAndroid extends MethodChannelEmbrace {
  /// Registers this class as the default instance of [EmbracePlatform]
  static void registerWith() {
    EmbracePlatform.instance = EmbraceAndroid();
  }
  // override classes here if needed
}
