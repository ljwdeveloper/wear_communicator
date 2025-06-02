import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_communicator_platform_interface.dart';

/// An implementation of [WearCommunicatorPlatform] that uses method channels.
class MethodChannelWearCommunicator extends WearCommunicatorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wear_communicator');
  static const _eventChannel = EventChannel('wear_communicator_event');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<void> sendMessage(Map<String, dynamic> message) async {
    // try {
    //   await methodChannel
    //       .invokeMethod<void>('sendMessage', {'message': message});
    // } on PlatformException {
    //   throw ArgumentError('Unable to send message $message');
    // }
    try {
      await methodChannel.invokeMethod<void>('sendMessage', {
        'message': message,
      });
    } on PlatformException catch (e) {
      log(
        'sendMessage failed: ${e.message}',
        error: e,
        name: 'MethodChannelWearCommunicator',
      );
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      log(
        'Unexpected error in sendMessage: $e',
        name: 'MethodChannelWearCommunicator',
      );
      throw Exception('Unexpected error while sending message');
    }
  }

  final BehaviorSubject<Map<String, dynamic>> _messageSubject =
      BehaviorSubject.seeded({});
  final BehaviorSubject<List<Map<String, dynamic>>> _connectionSubject =
      BehaviorSubject.seeded([]);

  MethodChannelWearCommunicator() {
    _listenToUnifiedEventChannel();
    _makeConnectionStream();
  }

  void _listenToUnifiedEventChannel() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        log('🔔 Event received from native: $event');

        if (event is Map) {
          final parsed = Map<String, dynamic>.from(
            event.map((k, v) => MapEntry(k.toString(), v)),
          );

          // if (parsed.containsKey("devices") && parsed["devices"] is List) {
          //   try {
          //     final devices = List<String>.from(parsed["devices"]);
          //     _connectionSubject.add(devices);
          //     return;
          //   } catch (e) {
          //     log('Failed to parse device list: $e');
          //   }
          // }

          // 메시지 이벤트 처리
          _messageSubject.add(parsed);
        }
      },
      onError: (error) {
        log('Unified event stream error: $error');
      },
    );
  }

  @override
  ValueStream<Map<String, dynamic>> get messageStream => _messageSubject.stream;

  @override
  ValueStream<List<Map<String, dynamic>>> get connectionStream =>
      _connectionSubject.stream;

  Timer? _connectionTimer;
  void _makeConnectionStream() async {
    var first = await _getConnectedDevices();
    _connectionSubject.add(first);
    _connectionTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      var devices = await _getConnectedDevices();
      _connectionSubject.add(devices);
    });
  }

  Future<List<Map<String, dynamic>>> _getConnectedDevices() async {
    // 이 메서드 통해서 현재의 디바이스 Node ID를 최신화한다.
    final raw = await methodChannel
        .invokeMethod<List<dynamic>>('getConnectedDevices')
        .timeout(Duration(seconds: 1), onTimeout: () => null);
    if (raw == null || raw.isEmpty) return [];
    var result = raw.map((value) => Map<String, dynamic>.from(value)).toList();
    return result;
  }

  @override
  void dispose() {
    if (!_messageSubject.isClosed) {
      _messageSubject.close();
    }
    if (!_connectionSubject.isClosed) {
      _connectionSubject.close();
    }
    _connectionTimer?.cancel();
  }
}
