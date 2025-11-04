import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes/router_config.dart';
import '../widgets/bind_cashier_dialog.dart';

class HomeController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final cashierName = ''.obs;
  final merchantCode = ''.obs;
  final cashierNumber = 'NO.00000'.obs;

  // Mock 变量:控制是否显示绑定收银台弹窗
  // true: 显示弹窗(设备未绑定), false: 不显示(设备已绑定)
  final bool shouldShowBindDialog = false;

  @override
  void onInit() {
    super.onInit();
    loadUserInfo();
  }

  /// 显示绑定收银台弹窗
  void showBindCashierDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 点击外部不关闭
      builder: (context) => const BindCashierDialog(),
    );
  }

  void loadUserInfo() {
    cashierName.value = _storage.getString(StorageKeys.cashierName) ?? 'Guest';
    merchantCode.value =
        _storage.getString(StorageKeys.merchantCode) ?? '100000';
  }

  void onMenuTap(String? path) {
    if (path == null || path.isEmpty) {
      print('Menu path is null or empty, no navigation');
      return;
    }
    print('Navigating to: $path');
    AppRouter.push(path);
  }

  void goToComponentsDemo() {
    AppRouter.push('/components-demo');
  }

  void goToDeviceSetup() {
    AppRouter.push('/device-setup');
  }
}
