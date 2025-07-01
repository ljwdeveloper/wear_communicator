import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rxdart/rxdart.dart';
import 'wearable_entity.dart';

import 'wear_communicator_method_channel.dart';
export 'package:rxdart/rxdart.dart';

abstract class WearCommunicatorPlatform extends PlatformInterface {
  /// Constructs a WearCommunicatorPlatform.
  WearCommunicatorPlatform() : super(token: _token);

  static final Object _token = Object();

  static WearCommunicatorPlatform _instance = MethodChannelWearCommunicator();

  /// The default instance of [WearCommunicatorPlatform] to use.
  ///
  /// Defaults to [MethodChannelWearCommunicator].
  static WearCommunicatorPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [WearCommunicatorPlatform] when
  /// they register themselves.
  static set instance(WearCommunicatorPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<void> initialize(String packageName, String className) {
    throw UnimplementedError('initialize() has not been implemented.');
  }

  Future<void> getLastCtrl() {
    throw UnimplementedError('getLastCtrl() has not been implemented.');
  }

  ConnectedDeviceEntity get thisDeviceInfo {
    throw UnimplementedError('thisDeviceInfo getter has not been implemented.');
  }

  Future<bool?> launchCompanionApp(String uriString) {
    throw UnimplementedError('launchCompanionApp() has not been implemented.');
  }

  /// Sends a message to the wearable device.
  // Future<void> sendMessage(Map<String, dynamic> message) {
  //   throw UnimplementedError('sendMessage() has not been implemented.');
  // }

  Future<void> sendCommand(CommandEntity command) {
    throw UnimplementedError('sendCommand() has not been implemented.');
  }

  Future<void> sendState(DevicePlayerStateEntity state) {
    throw UnimplementedError('sendState() has not been implemented.');
  }

  /// Receives a message from the wearable device.
  ValueStream<DevicePlayerStateEntity> get stateStream {
    throw UnimplementedError('stateStream getter has not been implemented.');
  }

  /// Receives a message from the wearable device.
  ValueStream<CommandEntity> get commandStream {
    throw UnimplementedError('commandStream getter has not been implemented.');
  }

  ValueStream<List<ConnectedDeviceEntity>> get connectionStream {
    throw UnimplementedError(
      'connectionStream getter has not been implemented.',
    );
  }

  ValueStream<ConnectedDeviceEntity> get controllingDeviceStream {
    throw UnimplementedError(
      'controllingDevice getter has not been implemented.',
    );
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
