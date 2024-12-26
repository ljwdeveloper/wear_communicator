import 'package:flutter_test/flutter_test.dart';
import 'package:wear_communicator/wear_communicator.dart';
import 'package:wear_communicator/wear_communicator_platform_interface.dart';
import 'package:wear_communicator/wear_communicator_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockWearCommunicatorPlatform
    with MockPlatformInterfaceMixin
    implements WearCommunicatorPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final WearCommunicatorPlatform initialPlatform = WearCommunicatorPlatform.instance;

  test('$MethodChannelWearCommunicator is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelWearCommunicator>());
  });

  test('getPlatformVersion', () async {
    WearCommunicator wearCommunicatorPlugin = WearCommunicator();
    MockWearCommunicatorPlatform fakePlatform = MockWearCommunicatorPlatform();
    WearCommunicatorPlatform.instance = fakePlatform;

    expect(await wearCommunicatorPlugin.getPlatformVersion(), '42');
  });
}
