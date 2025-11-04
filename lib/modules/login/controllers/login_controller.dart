import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/models/auth/login_request.dart';
import '../../../app/routes/router_config.dart';
import 'quick_login_controller.dart';

class LoginController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final AuthService _authService = AuthService();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final isQuickLogin = false.obs;
  final selectedUsername = ''.obs;

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  void selectQuickUser(String username) {
    usernameController.text = username;
    selectedUsername.value = username;
    isQuickLogin.value = true;
    passwordController.clear();
  }

  void clearQuickLogin() {
    usernameController.clear();
    passwordController.clear();
    selectedUsername.value = '';
    isQuickLogin.value = false;
  }

  Future<void> login(BuildContext context) async {
    // 验证账号
    if (usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入账号', style: TextStyle(fontSize: 14.sp)),
          backgroundColor: Colors.black.withOpacity(0.82),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // 验证密码
    final password = passwordController.text.trim();
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请输入密码', style: TextStyle(fontSize: 14.sp)),
          backgroundColor: Colors.black.withOpacity(0.82),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    isLoading.value = true;

    try {
      // 调用登录接口
      final request = LoginRequest(
        username: usernameController.text,
        password: password,
        deviceCode: 'flutter_device_001', // 临时设备码
      );

      final response = await _authService.login(request);

      // 保存用户信息
      if (response.token != null) {
        await _storage.setString(StorageKeys.token, response.token!);
      }
      if (response.tokenName != null) {
        await _storage.setString(StorageKeys.tokenName, response.tokenName!);
      }
      if (response.userInfo != null) {
        final userInfo = response.userInfo!;
        if (userInfo.userId != null) {
          await _storage.setString(StorageKeys.userId, userInfo.userId!);
        }
        if (userInfo.cashierName != null) {
          await _storage.setString(
            StorageKeys.cashierName,
            userInfo.cashierName!,
          );
        }
        if (userInfo.merchantCode != null) {
          await _storage.setString(
            StorageKeys.merchantCode,
            userInfo.merchantCode!,
          );
        }
      }

      final quickLoginController = Get.find<QuickLoginController>();
      final name =
          response.userInfo?.cashierName ?? response.userInfo?.username;
      await quickLoginController.addUser(usernameController.text, name);

      AppRouter.replace('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: TextStyle(fontSize: 14.sp),
          ),
          backgroundColor: Colors.black.withOpacity(0.82),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }
}
