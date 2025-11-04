import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../network_check/controllers/network_check_controller.dart';
import '../../../data/models/network_status.dart';
import '../../../l10n/app_localizations.dart';

/// 设置模块中的网络检测视图
/// 复用登录页面的网络检测功能，按照新设计样式呈现
class NetworkDetectionView extends StatelessWidget {
  const NetworkDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 使用已有的NetworkCheckController
    final controller = Get.find<NetworkCheckController>();

    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(40.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 标题：网络检测完成
          Text(
            '网络检测完成!',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 40.h),

          // 检测结果区域
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Column(
              children: [
                // 外网连接状态
                _buildResultItem(
                  label: l10n.externalConnectionStatus,
                  statusObservable: controller.externalConnectionStatus,
                  controller: controller,
                ),
                SizedBox(height: 20.h),

                // 中心服务器连接状态
                _buildResultItem(
                  label: l10n.centerServerConnectionStatus,
                  statusObservable: controller.centerServerConnectionStatus,
                  controller: controller,
                ),
                SizedBox(height: 20.h),

                // 外网Ping检测结果
                _buildResultItem(
                  label: l10n.externalPingResult,
                  statusObservable: controller.externalPingStatus,
                  controller: controller,
                  showLatency: true,
                ),
                SizedBox(height: 20.h),

                // DNS服务器Ping检测结果
                _buildResultItem(
                  label: l10n.dnsPingResult,
                  statusObservable: controller.dnsPingStatus,
                  controller: controller,
                  showLatency: true,
                ),
                SizedBox(height: 20.h),

                // 中心服务器Ping检测结果
                _buildResultItem(
                  label: l10n.centerServerPingResult,
                  statusObservable: controller.centerServerPingStatus,
                  controller: controller,
                  showLatency: true,
                ),
              ],
            ),
          ),

          SizedBox(height: 40.h),

          // 底部按钮
          Row(
            children: [
              // 关闭按钮
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400, width: 1.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '关闭',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.w),

              // 重新检测按钮
              Expanded(
                child: SizedBox(
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: controller.checkAll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: Text(
                      '重新检测',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建检测结果项
  Widget _buildResultItem({
    required String label,
    required Rx<NetworkCheckResult> statusObservable,
    required NetworkCheckController controller,
    bool showLatency = false,
  }) {
    return Obx(() {
      final result = statusObservable.value;
      final isSuccess = result.status == NetworkCheckStatus.success;
      final isFailed = result.status == NetworkCheckStatus.failed;

      return Row(
        children: [
          // 状态图标
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSuccess
                  ? Colors.green.shade50
                  : isFailed
                      ? Colors.red.shade50
                      : Colors.grey.shade200,
            ),
            child: Icon(
              isSuccess
                  ? Icons.check
                  : isFailed
                      ? Icons.close
                      : Icons.remove,
              size: 20.sp,
              color: isSuccess
                  ? Colors.green.shade600
                  : isFailed
                      ? Colors.red.shade600
                      : Colors.grey.shade500,
            ),
          ),
          SizedBox(width: 16.w),

          // 标签
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // 状态文本
          Expanded(
            flex: 1,
            child: Text(
              _getStatusDisplayText(result, showLatency),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 15.sp,
                color: isSuccess
                    ? Colors.green.shade600
                    : isFailed
                        ? Colors.red.shade600
                        : Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    });
  }

  /// 获取状态显示文本
  String _getStatusDisplayText(NetworkCheckResult result, bool showLatency) {
    switch (result.status) {
      case NetworkCheckStatus.pending:
        return '待检测';
      case NetworkCheckStatus.checking:
        return '检测中...';
      case NetworkCheckStatus.success:
        if (showLatency && result.latency != null) {
          return '成功 (平均耗时: ${result.latency}ms)';
        }
        return '成功';
      case NetworkCheckStatus.failed:
        return '失败';
    }
  }
}
