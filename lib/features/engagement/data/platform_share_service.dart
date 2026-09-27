import 'package:flutter/services.dart';

import '../../catalog/domain/drama.dart';

class PlatformShareService {
  const PlatformShareService();

  static const _channel = MethodChannel('com.stormg.lumadrama/share');

  Future<void> shareDrama(Drama drama) => _channel.invokeMethod<void>(
    'shareText',
    {'text': '${drama.title}\n${drama.synopsis}\nLumaDrama demo'},
  );
}
