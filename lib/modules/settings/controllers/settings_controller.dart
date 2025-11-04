import 'package:get/get.dart';

class SettingsController extends GetxController {
  final selectedMenu = RxString('external_card_reader');
  final deviceId = RxString('');
  final versionInfo = RxString('');
  final updateTime = RxString('');

  @override
  void onInit() {
    super.onInit();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    deviceId.value = 'test_id';
    versionInfo.value = '1.2.34';
    updateTime.value = '2025-08-01 12:00:00';
  }

  void selectMenu(String menu) {
    selectedMenu.value = menu;
  }

  Future<void> checkUpdate() async {
    // TODO: 实现检查更新逻辑
  }
}
