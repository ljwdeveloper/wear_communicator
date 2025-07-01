import 'wear_communicator_platform_interface.dart';
import 'wearable_entity.dart';
export 'wearable_entity.dart';

class WearCommunicator {
  Future<void> initialize(String packageName, String className) {
    return WearCommunicatorPlatform.instance.initialize(packageName, className);
  }

  Future<void> getLastCtrl() {
    return WearCommunicatorPlatform.instance.getLastCtrl();
  }

  ConnectedDeviceEntity get thisDeviceInfo {
    return WearCommunicatorPlatform.instance.thisDeviceInfo;
  }

  Future<bool?> launchCompanionApp(String uriString) {
    return WearCommunicatorPlatform.instance.launchCompanionApp(uriString);
  }

  Future<void> sendCommand(CommandEntity command) {
    return WearCommunicatorPlatform.instance.sendCommand(command);
  }

  Future<void> sendState(DevicePlayerStateEntity state) {
    return WearCommunicatorPlatform.instance.sendState(state);
  }

  /// 제어중인 디바이스가 전달하는 재생상태 스트림.
  ValueStream<DevicePlayerStateEntity> get stateStream =>
      WearCommunicatorPlatform.instance.stateStream;

  /// 이 디바이스가 구독해야 할 명령 스트림.
  /// 타겟미지정(broadcast) 또는 이 디바이스 타겟인 데이터가 전송됨.
  ValueStream<CommandEntity> get commandStream =>
      WearCommunicatorPlatform.instance.commandStream;

  /// Android:
  /// ```json
  /// [{"id": "b99c78f0", "name": "Galaxy Z Fold4", "isNearby": true}, {"id": "38ac9e77", "name": "Galaxy Watch6 Classic (YPXM)", "isNearby": true}]
  /// ```
  ValueStream<List<ConnectedDeviceEntity>> get deviceChangeStream =>
      WearCommunicatorPlatform.instance.connectionStream;
  ValueStream<ConnectedDeviceEntity> get controllingDeviceStream =>
      WearCommunicatorPlatform.instance.controllingDeviceStream;

  void dispose() => WearCommunicatorPlatform.instance.dispose();
}
