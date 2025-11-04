import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../controllers/device_setup_controller.dart';
import '../../../data/services/sunmi_printer_service.dart';
import '../widgets/printer_setup_layout.dart';
import '../widgets/printer_status_display.dart';
import '../widgets/printer_instructions_panel.dart';
import '../widgets/printer_action_buttons.dart';
import '../widgets/draggable_log_panel.dart';

/// 打印机设置页面 - 内置打印机配置
/// 只保留内置打印机配置功能
/// 外置打印机已迁移至【设置】模块
class PrinterSetupPage extends GetView<DeviceSetupController> {
  const PrinterSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 主要内容
        PrinterSetupLayout(
          title: '打印机',
          mainContent: Obx(() => _buildMainContent()),
          recognitionStatus: Obx(() => _buildRecognitionStatus()),
          bottomButtons: Obx(() => _buildBottomButtons()),
        ),
        
        // 可拖动的日志面板（悬浮在最右侧）
        const DraggableLogPanel(),
      ],
    );
  }

  /// 主内容区域 - 2列布局（操作提示 + 内置打印机）
  Widget _buildMainContent() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 第1列：操作提示（30%宽度）
        Expanded(
          flex: 30,
          child: _buildInstructionsPanel(),
        ),
        
        SizedBox(width: 20.w),
        
        // 第2列：内置打印机（70%宽度，居中显示）
        Expanded(
          flex: 70,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 600.w),
              child: _buildBuiltInPrinterPanel(),
            ),
          ),
        ),
      ],
    );
  }

  /// 第1列：操作提示
  Widget _buildInstructionsPanel() {
    return const PrinterInstructionsPanel();
  }

  /// 第2列：内置打印机面板（带标题）
  Widget _buildBuiltInPrinterPanel() {
    final printerService = Get.find<SunmiPrinterService>();
    final checkStatus = controller.printerCheckStatus.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF52C41A), width: 2.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52C41A).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题栏
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FFED),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14.r),
                topRight: Radius.circular(14.r),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF52C41A),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.print,
                    size: 28.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '内置打印机',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF52C41A),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Sunmi内置热敏打印机',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 内容区域（使用Flexible自适应）
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 打印机状态显示
                  PrinterStatusDisplay(
                    statusInfo: printerService.printerStatus.value,
                    isChecking: checkStatus == 'checking',
                  ),
                  
                  SizedBox(height: 20.h),
                  
                  // 操作按钮
                  const PrinterActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }





  /// 识别状态（测试成功后显示）
  Widget _buildRecognitionStatus() {
    final testStatus = controller.printerTestStatus.value;

    if (testStatus != 'success') {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: 56.w,
          height: 56.h,
          decoration: const BoxDecoration(
            color: Color(0xFF52C41A),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, size: 32.sp, color: Colors.white),
        ),
        SizedBox(height: 12.h),
        Text(
          '测试通过',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF52C41A),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '打印机配置成功',
          style: TextStyle(
            fontSize: 14.sp,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 底部按钮
  Widget _buildBottomButtons() {
    final isCompleted = controller.printerCompleted.value;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 600.w),
        child: Column(
          children: [
            // 下一步按钮
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: isCompleted ? controller.completeSetup : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
                  backgroundColor: const Color(0xFFE5B544),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  disabledForegroundColor: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  '下一步',
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            SizedBox(height: 12.h),

            // 稍后设置链接
            TextButton(
              onPressed: controller.skipCurrentStep,
              child: Text(
                '稍后设置"硬件"',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: const Color(0xFF1890FF),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
