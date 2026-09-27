import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Android activity PiP; the Flutter playback session keeps the player.
class AndroidPictureInPicture {
  AndroidPictureInPicture({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.stormg.lumadrama/pip');

  final MethodChannel _channel;

  bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void setStateListener(ValueChanged<bool>? listener) {
    _channel.setMethodCallHandler(
      listener == null
          ? null
          : (call) async {
              if (call.method == 'onPipChanged') {
                listener(call.arguments == true);
              }
            },
    );
  }

  Future<bool> enter() async {
    if (!isPlatformSupported) return false;
    return await _channel.invokeMethod<bool>('enter') ?? false;
  }
}
