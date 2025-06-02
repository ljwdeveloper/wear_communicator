import 'wear_communicator_platform_interface.dart';

class WearCommunicator {
  Future<String?> getPlatformVersion() {
    return WearCommunicatorPlatform.instance.getPlatformVersion();
  }

  /// Sends a message to the wearable device.
  Future<void> sendMessage(Map<String, dynamic> message) {
    return WearCommunicatorPlatform.instance.sendMessage(message);
  }

  /// Stream to listen for messages from the wearable device.
  ValueStream<Map<String, dynamic>> get messageStream =>
      WearCommunicatorPlatform.instance.messageStream;

  ValueStream<List<Map<String, dynamic>>> get deviceChangeStream =>
      WearCommunicatorPlatform.instance.connectionStream;

  void dispose() => WearCommunicatorPlatform.instance.dispose();
}
