import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/services/external_card_reader_service.dart';
import '../../../data/models/external_card_reader_model.dart';
import '../widgets/card_reader_device_status.dart';
import '../widgets/card_reader_data_display.dart';

/// 外置读卡器配置页面
/// 用于配置和测试通过USB连接的外置读卡器设备
class ExternalCardReaderView extends StatefulWidget {
  const ExternalCardReaderView({super.key});

  @override
  State<ExternalCardReaderView> createState() => _ExternalCardReaderViewState();
}

class _ExternalCardReaderViewState extends State<ExternalCardReaderView> {
  late final ExternalCardReaderService _readerService;

  @override
  void initState() {
    super.initState();
    _readerService = Get.put(ExternalCardReaderService());
    _readerService.init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        children: [
          // 顶部操作栏
          _buildTopBar(),
          
          // 主要内容区域（左右分栏）
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  /// 顶部操作栏
  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8E8E8),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 标题
          Text(
            '外置读卡器配置',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          
          const Spacer(),
          
          // 扫描设备按钮
          Obx(() => ElevatedButton.icon(
            onPressed: _readerService.isScanning.value
                ? null
                : () => _readerService.scanUsbReaders(),
            icon: Icon(
              _readerService.isScanning.value ? Icons.sync : Icons.refresh,
              size: 18.sp,
            ),
            label: Text(
              _readerService.isScanning.value ? '扫描中...' : '扫描设备',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1890FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
          )),
          
          SizedBox(width: 12.w),
          
          // 查看日志按钮
          TextButton.icon(
            onPressed: _showDebugLogs,
            icon: Icon(Icons.bug_report, size: 18.sp),
            label: Text(
              '日志',
              style: TextStyle(fontSize: 14.sp),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  /// 主要内容区域
  Widget _buildMainContent() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 左侧：设备信息和操作
          Expanded(
            flex: 45,
            child: _buildLeftSection(),
          ),
          
          SizedBox(width: 24.w),
          
          // 右侧：卡片数据显示
          Expanded(
            flex: 55,
            child: _buildRightSection(),
          ),
        ],
      ),
    );
  }

  /// 左侧区域：设备信息和操作
  Widget _buildLeftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Text(
          '设备信息',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // 设备状态显示
        Obx(() => CardReaderDeviceStatus(
          device: _readerService.selectedReader.value,
          status: _readerService.readerStatus.value,
          isScanning: _readerService.isScanning.value,
        )),
        
        SizedBox(height: 24.h),
        
        // 操作按钮
        Obx(() => _buildActionButtons()),
      ],
    );
  }

  /// 右侧区域：卡片数据显示
  Widget _buildRightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 区域标题
        Text(
          '卡片数据',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF333333),
          ),
        ),
        
        SizedBox(height: 16.h),
        
        // 卡片数据显示
        Expanded(
          child: SingleChildScrollView(
            child: Obx(() => CardReaderDataDisplay(
              cardData: _readerService.cardData.value,
            )),
          ),
        ),
      ],
    );
  }

  /// 操作按钮
  Widget _buildActionButtons() {
    final hasDevice = _readerService.selectedReader.value != null;
    final isReading = _readerService.isReading.value;
    final isConnected = _readerService.readerStatus.value == ExternalCardReaderStatus.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 测试读卡按钮
        SizedBox(
          height: 48.h,
          child: ElevatedButton.icon(
            onPressed: hasDevice && isConnected && !isReading
                ? _testReadCard
                : null,
            icon: Icon(
              isReading ? Icons.sync : Icons.credit_card,
              size: 18.sp,
            ),
            label: Text(
              isReading ? '读卡中...' : '测试读卡',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5B544),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE0E0E0),
              disabledForegroundColor: const Color(0xFF999999),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
          ),
        ),
        
        SizedBox(height: 12.h),
        
        // 清除数据按钮
        SizedBox(
          height: 48.h,
          child: OutlinedButton.icon(
            onPressed: _readerService.cardData.value != null
                ? _clearCardData
                : null,
            icon: Icon(Icons.clear, size: 18.sp),
            label: Text(
              '清除数据',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF666666),
              disabledForegroundColor: const Color(0xFF999999),
              side: const BorderSide(color: Color(0xFFD9D9D9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        
        // 状态提示
        if (!hasDevice) ...[
          SizedBox(height: 16.h),
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBE6),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: const Color(0xFFF39C12),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18.sp,
                  color: const Color(0xFFF39C12),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    '请先连接USB读卡器设备',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: const Color(0xFFF39C12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 测试读卡
  Future<void> _testReadCard() async {
    final result = await _readerService.testReadCard();
    
    if (!mounted) return;
    
    if (result.success) {
      Get.snackbar(
        '读卡成功',
        '已成功读取卡片数据',
        backgroundColor: const Color(0xFF52C41A),
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    } else {
      Get.snackbar(
        '读卡失败',
        result.message,
        backgroundColor: const Color(0xFFE74C3C),
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// 清除卡片数据
  void _clearCardData() {
    _readerService.clearCardData();
    Get.snackbar(
      '已清除',
      '卡片数据已清除',
      backgroundColor: const Color(0xFF1890FF),
      colorText: Colors.white,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 1),
    );
  }

  /// 显示调试日志
  void _showDebugLogs() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 800.w,
          height: 600.h,
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '调试日志',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => _readerService.clearLogs(),
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '清空日志',
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Obx(() => ListView.builder(
                    itemCount: _readerService.debugLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          _readerService.debugLogs[index],
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontFamily: 'monospace',
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
