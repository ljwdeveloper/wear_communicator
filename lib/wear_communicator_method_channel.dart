import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'wear_communicator_platform_interface.dart';
import 'wearable_entity.dart';

/// An implementation of [WearCommunicatorPlatform] that uses method channels.
class MethodChannelWearCommunicator extends WearCommunicatorPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('wear_communicator');
  static const _eventChannel = EventChannel('wear_communicator_event');

  ConnectedDeviceEntity _thisDeviceInfo = ConnectedDeviceEntity();
  @override
  ConnectedDeviceEntity get thisDeviceInfo => _thisDeviceInfo;

  @override
  Future<void> initialize(String packageName, String className) async {
    try {
      await methodChannel.invokeMethod<void>('setPackageNameClassName', {
        'packageName': packageName,
        'className': className,
      });
    } catch (e) {
      log(
        'Unexpected error in initialize: $e',
        name: 'MethodChannelWearCommunicator',
      );
    }
  }

  @override
  Future<void> getLastCtrl() async {
    try {
      await methodChannel.invokeMethod<void>('sendMessage', {
        'messageType': 'getLastCtrl',
      });
    } catch (e) {
      log(
        'Unexpected error in getLastCtrl: $e',
        name: 'MethodChannelWearCommunicator',
      );
    }
  }

  @override
  Future<bool?> launchCompanionApp(String uriString) async {
    var result =
        await methodChannel.invokeMethod<bool>('launchCompanionApp', uriString);
    log('f: launchCompanionApp result: $result',
        name: 'MethodChannelWearCommunicator');
    return result;
  }

  // Future<bool?> startMediaService(bool play) async {
  //   var result =
  //       await methodChannel.invokeMethod<bool>('startMediaService', play);
  //   log('f: startMediaService result: $result',
  //       name: 'MethodChannelWearCommunicator');
  //   return result;
  // }

  Future<void> _sendMessage(Map<String, dynamic> message) async {
    try {
      await methodChannel.invokeMethod<void>('sendMessage', message);
    } on PlatformException catch (e) {
      log(
        'sendMessage failed: ${e.message}',
        error: e,
        name: 'MethodChannelWearCommunicator',
      );
      // throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      log(
        'Unexpected error in sendMessage: $e',
        name: 'MethodChannelWearCommunicator',
      );
      // throw Exception('Unexpected error while sending message');
    }
  }

/**
 * 명령에 target이 없으면 broadcast의미. 이 경우 _notProcessedCommand를
 * 설정하지 않는다.
 * target이 지정된 명령은 발송측과 수신측 모두 _notProcessedCommand를
 * 설정하자.
 */
  CommandEntity? _notProcessedCommand;
  @override
  Future<void> sendCommand(CommandEntity command) async {
    if (command.target != null) {
      if (command.commandFinished) {
        _controllingDeviceSubject.add(command.target!);
        if (_notProcessedCommand?.cmdId == command.cmdId) {
          _notProcessedCommand == null;
        }
      } else {
        _notProcessedCommand = command;
      }
    }
    Map<String, dynamic> message = command.toJson();
    await _sendMessage(message);
  }

  DevicePlayerStateEntity? _thisDeviceLastState;
  @override
  Future<void> sendState(DevicePlayerStateEntity state) async {
    _thisDeviceLastState = state;
    Map<String, dynamic> message = state.toJson();
    await _sendMessage(message);
  }

  // final BehaviorSubject<Map<String, dynamic>> _messageSubject =
  //     BehaviorSubject.seeded({});
  final BehaviorSubject<CommandEntity> _commandSubject = BehaviorSubject();
  final BehaviorSubject<DevicePlayerStateEntity> _stateSubject =
      BehaviorSubject();
  final BehaviorSubject<List<ConnectedDeviceEntity>> _connectionSubject =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<ConnectedDeviceEntity> _controllingDeviceSubject =
      BehaviorSubject.seeded(ConnectedDeviceEntity());

  MethodChannelWearCommunicator() {
    _listenToUnifiedEventChannel();
    _makeConnectionStream();
  }

  void _listenToUnifiedEventChannel() {
    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        log('🔔 Event received from native: $event',
            name: 'MethodChannelWearCommunicator');
        if (event is! Map) return;
        if (event.isEmpty) return;

        final json = _convertToStringDynamicMap(event);
        // 메시지 이벤트 처리
        if (json['messageType'] == 'command') {
          CommandEntity entity = CommandEntity.fromJson(json);
          _commandListener(entity);
        } else if (json['messageType'] == 'state') {
          DevicePlayerStateEntity entity =
              DevicePlayerStateEntity.fromJson(json);
          _stateListener(entity);
        } else if (json['messageType'] == 'getLastCtrl') {
          if (_thisDeviceLastState == null) return; // 이런 경우가 있을지 모르겠으나 예외처리
          if (_thisDeviceLastState!.ctrlDevice != thisDeviceInfo) return;
          if (_notProcessedCommand != null) {
            sendCommand(_notProcessedCommand!);
          } else {
            sendState(_thisDeviceLastState!);
          }
        }
      },
      onError: (e) {
        log('Unified event stream error: $e',
            error: e, name: 'MethodChannelWearCommunicator');
      },
    );
  }

  // target device가 현재의 기기라면 commandFinished=true인 동일 entity를 response 해야함
  void _commandListener(CommandEntity entity) {
    if (entity.sender.isEmpty) return;
    if (entity.commandFinished &&
        (_notProcessedCommand?.cmdId == entity.cmdId)) {
      // target device(제3기기 염두)가 명령에 대해 response한 상황.
      // 이 response 받았다면 _notProcessedCommand를 없애자.
      _notProcessedCommand = null;
      if (entity.target != null) {
        _controllingDeviceSubject.add(entity.target!);
      }
    }

    // else if (entity.target == null) {
    //   _commandSubject.add(entity);
    // } else if (entity.target == thisDeviceInfo) {
    //   _commandSubject.add(entity);
    // }
    _commandSubject.add(entity);
  }

  void _stateListener(DevicePlayerStateEntity entity) {
    if (entity.ctrlDevice == thisDeviceInfo) return;
    _stateSubject.add(entity);
    _controllingDeviceSubject.add(entity.ctrlDevice);
  }

  Map<String, dynamic> _convertToStringDynamicMap(Map input) {
    return input.map<String, dynamic>((key, value) {
      final newKey = key.toString();
      final newValue = _convertValue(value);
      return MapEntry(newKey, newValue);
    });
  }

  dynamic _convertValue(dynamic value) {
    if (value is Map) {
      return _convertToStringDynamicMap(value);
    } else if (value is List) {
      return value.map(_convertValue).toList();
    } else {
      return value;
    }
  }

  @override
  ValueStream<DevicePlayerStateEntity> get stateStream => _stateSubject.stream;

  @override
  ValueStream<CommandEntity> get commandStream => _commandSubject.stream;

  @override
  ValueStream<List<ConnectedDeviceEntity>> get connectionStream =>
      _connectionSubject.stream;

  @override
  ValueStream<ConnectedDeviceEntity> get controllingDeviceStream =>
      _controllingDeviceSubject.stream;

  Timer? _connectionTimer;
  void _makeConnectionStream() async {
    var first = await _getConnectedDevices();
    _connectionSubject.add(first);
    _connectionTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      var devices = await _getConnectedDevices();
      _connectionSubject.add(devices);
    });
  }

  Future<List<ConnectedDeviceEntity>> _getConnectedDevices() async {
    // 이 메서드 통해서 현재의 디바이스 Node ID를 최신화한다.
    List<dynamic> raw = [];
    try {
      raw = await methodChannel
              .invokeListMethod('getConnectedDevices')
              .timeout(Duration(seconds: 3), onTimeout: () => null) ??
          [];
    } catch (e) {
      log('_getConnectedDevices error: $e',
          error: e, name: 'MethodChannelWearCommunicator');
    }
    if (raw.isEmpty) return [];
    // [{id: b99c78f0, name: Galaxy Z Fold4, isNearby: true}, {id: 38ac9e77, name: Galaxy Watch6 Classic (YPXM), isNearby: true}]
    var result = raw
        .map((value) =>
            ConnectedDeviceEntity.fromJson(Map<String, dynamic>.from(value)))
        .toList();
    _thisDeviceInfo = result.first;
    if (_controllingDeviceSubject.value.isEmpty) {
      _controllingDeviceSubject.add(_thisDeviceInfo);
    }
    return result;
  }

  @override
  void dispose() {
    log('dispose', name: 'MethodChannelWearCommunicator');
    // if (!_commandSubject.isClosed) {
    //   _commandSubject.close();
    // }
    // if (!_stateSubject.isClosed) {
    //   _stateSubject.close();
    // }
    // if (!_connectionSubject.isClosed) {
    //   _connectionSubject.close();
    // }
    _connectionTimer?.cancel();
  }
}
