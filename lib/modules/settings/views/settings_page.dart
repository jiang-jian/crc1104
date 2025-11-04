import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../modules/network_check/widgets/network_check_widget.dart';
import '../controllers/settings_controller.dart';
import 'version_check_view.dart';
import 'change_password_view.dart';
import 'placeholder_view.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Obx(
                      () => _buildContent(controller.selectedMenu.value),
                    ),
                  ),
                ),
                _buildSidebar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final menuItems = [
      ('qr_scanner', '二维码扫描仪', Icons.qr_code_2),
      ('printer', '打印机', Icons.print),
      ('network_check', '网络检查', Icons.wifi),
      ('receipt_settings', '小票设置', Icons.receipt),
      ('card_level', '卡片等级', Icons.card_membership),
      ('game_management', '游戏管理', Icons.games),
      ('change_password', '修改登录密码', Icons.lock),
      ('version_check', '版本检查', Icons.info),
    ];

    return Container(
      width: 200.w,
      color: const Color(0xFF2C3E50),
      child: ListView.builder(
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final (key, label, icon) = menuItems[index];
          return Obx(
            () => Container(
              color: controller.selectedMenu.value == key
                  ? const Color(0xFFE5B544)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => controller.selectMenu(key),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 20.sp,
                        color: controller.selectedMenu.value == key
                            ? Colors.white
                            : Colors.grey[300],
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: controller.selectedMenu.value == key
                                ? Colors.white
                                : Colors.grey[300],
                            fontWeight: controller.selectedMenu.value == key
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(String selectedMenu) {
    Widget content;
    switch (selectedMenu) {
      case 'network_check':
        content = const NetworkCheckWidget();
        break;
      case 'version_check':
        content = const VersionCheckView();
        break;
      case 'change_password':
        content = const ChangePasswordView();
        break;
      default:
        content = const PlaceholderView();
    }
    
    return Container(
      width: 1000.w,
      padding: EdgeInsets.all(12.w),
      child: content,
    );
  }
}
