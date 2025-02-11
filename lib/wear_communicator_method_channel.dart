import 'dart:developer';
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
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    try {
      await methodChannel
          .invokeMethod<void>('sendMessage', {'message': message});
    } on PlatformException {
      throw ArgumentError('Unable to send message $message');
    }
  }

  @override
  Stream<Map<String, dynamic>> onMessageReceived() {
    const EventChannel eventChannel = EventChannel('wear_communicator_events');
    return eventChannel.receiveBroadcastStream().map((event) {
      log('f: onMessageReceived / event : $event / type : ${event.runtimeType}',
          name: runtimeType.toString());
      Map<String, dynamic> result = {};
      try {
        result = Map<String, dynamic>.from(
          event.map((key, value) => MapEntry(key.toString(), value)),
        );
        log('f: onMessageReceived / result : $result / type : ${result.runtimeType}',
            name: runtimeType.toString());
      } catch (e) {
        log('f: onMessageReceived parsing failed: $e',
            name: runtimeType.toString());
      }
      return result;
    });
  }
}
