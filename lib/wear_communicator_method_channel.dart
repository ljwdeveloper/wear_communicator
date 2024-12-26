import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_communicator_platform_interface.dart';

/// An implementation of [WearCommunicatorPlatform] that uses method channels.
class MethodChannelWearCommunicator extends WearCommunicatorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wear_communicator');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
