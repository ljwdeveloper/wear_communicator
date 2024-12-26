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
  Stream<Map<String, dynamic>> onMessageReceived() {
    return WearCommunicatorPlatform.instance.onMessageReceived();
  }
}
