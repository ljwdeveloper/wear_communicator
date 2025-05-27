import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rxdart/rxdart.dart';

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

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Sends a message to the wearable device.
  Future<void> sendMessage(Map<String, dynamic> message) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  /// Receives a message from the wearable device.
  ValueStream<Map<String, dynamic>> get messageStream {
    throw UnimplementedError('messageStream getter has not been implemented.');
  }

  ValueStream<List<String>> get connectionStream {
    throw UnimplementedError(
      'connectionStream getter has not been implemented.',
    );
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
