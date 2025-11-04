import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../data/services/external_card_reader_service.dart';
import '../../../data/models/external_card_reader_model.dart';
import '../widgets/card_reader_device_status.dart';
import '../widgets/card_reader_data_display.dart';

/// 外置读卡器配置页面（优化版）
/// 对齐外置打印机页面样式：紫色按钮，扫描按钮置顶
class ExternalCardReaderView extends StatelessWidget {
  const ExternalCardReaderView({super.key});

  @override
  Widget build(BuildContext context) {
    // 确保服务已注册
    ExternalCardReaderService service;
    try {
      service = Get.find<ExternalCardReaderService>();
    } catch (e) {
      service = Get.put(ExternalCardReaderService());
      service.init();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 32.h),
          Expanded(
            child: _buildContent(service),
          ),
        ],
      ),
    );
  }

  /// 页面头部
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0), // 紫色主题
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            Icons.credit_card,
            size: 32.sp,
            color: Colors.white,
          ),
        ),
        SizedBox(width: 16.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '外置读卡器配置',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '管理USB外接读卡器设备',
              style: TextStyle(
                fontSize: 16.sp,
                color: const Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
        const Spacer(),
        // 日志按钮
        TextButton.icon(
          onPressed: () => _showDebugLogs(Get.find<ExternalCardReaderService>()),
          icon: Icon(Icons.bug_report, size: 18.sp),
          label: Text('日志', style: TextStyle(fontSize: 14.sp)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  /// 主内容区域
  Widget _buildContent(ExternalCardReaderService service) {
    return Obx(() {
      // 扫描中状态
      if (service.isScanning.value) {
        return Column(
          children: [
            _buildScanButton(service),
            SizedBox(height: 32.h),
            Expanded(child: _buildScanningState()),
          ],
        );
      }

      // 未检测到设备
      if (service.detectedReaders.isEmpty) {
        return Column(
          children: [
            _buildScanButton(service),
            SizedBox(height: 32.h),
            Expanded(child: _buildEmptyState()),
          ],
        );
      }

      // 有设备，显示扫描按钮+设备信息+读卡提示
      final selectedDevice = service.selectedReader.value;
      if (selectedDevice != null) {
        return _buildThreeColumnLayout(selectedDevice, service);
      }

      // 有设备但未选择
      return Column(
        children: [
          _buildScanButton(service),
          SizedBox(height: 32.h),
          Expanded(child: _buildEmptyState()),
        ],
      );
    });
  }

  /// 三列布局（扫描、信息、读卡提示）
  Widget _buildThreeColumnLayout(
    ExternalCardReaderDevice device,
    ExternalCardReaderService service,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 第1块：扫描USB设备按钮（紫色，置顶）
          _buildScanButton(service),

          SizedBox(height: 24.h),

          // 第2块：读卡器基础信息
          _buildReaderInfo(device),

          SizedBox(height: 24.h),

          // 第3块：读卡提示和卡片数据显示
          _buildReadCardSection(device, service),
        ],
      ),
    );
  }

  /// 扫描按钮（紫色，对齐打印机样式）
  Widget _buildScanButton(ExternalCardReaderService service) {
    return Obx(() => SizedBox(
          height: 50.h,
          width: 400.w,
          child: ElevatedButton.icon(
            onPressed: service.isScanning.value
                ? null
                : () => service.scanUsbReaders(),
            icon: service.isScanning.value
                ? SizedBox(
                    width: 20.w,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh, size: 22.sp),
            label: Text(
              service.isScanning.value ? '扫描中...' : '扫描USB设备',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9C27B0), // 紫色
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
        ));
  }

  /// 读卡器信息卡片
  Widget _buildReaderInfo(ExternalCardReaderDevice device) {
    return Container(
      width: 420.w,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 设备图标和名称
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.credit_card,
                  size: 28.sp,
                  color: const Color(0xFF9C27B0),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.model,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.h,
                          decoration: const BoxDecoration(
                            color: Color(0xFF52C41A), // 绿色
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '已连接',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFF52C41A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.h),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          SizedBox(height: 16.h),
          
          // 设备详细信息
          _buildInfoRow('厂商', device.manufacturer),
          SizedBox(height: 12.h),
          _buildInfoRow('型号', device.model ?? 'Unknown'),
          SizedBox(height: 12.h),
          _buildInfoRow('规格', device.specifications ?? 'Unknown'),
          SizedBox(height: 12.h),
          _buildInfoRow('USB ID', device.usbIdentifier),
        ],
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7F8C8D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C3E50),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 读卡区域（提示 + 卡片数据）
  Widget _buildReadCardSection(
    ExternalCardReaderDevice device,
    ExternalCardReaderService service,
  ) {
    return Obx(() {
      final cardData = service.cardData.value;
      final isReading = service.isReading.value;
      final isConnected = service.readerStatus.value == ExternalCardReaderStatus.connected;

      return Container(
        width: 420.w,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 如果没有读取到卡片数据，显示提示
            if (cardData == null) ...[
              // 图标和提示文字
              Container(
                padding: EdgeInsets.symmetric(vertical: 24.h),
                child: Column(
                  children: [
                    // 卡片图标
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5B544).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isReading ? Icons.sync : Icons.credit_card_outlined,
                        size: 48.sp,
                        color: const Color(0xFFE5B544),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    // 提示文字
                    Text(
                      isReading 
                          ? '读卡中，请稍候...'
                          : isConnected
                              ? '请您将卡片放置到外置读卡器上'
                              : '设备未连接',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: isReading 
                            ? const Color(0xFF1890FF)
                            : isConnected
                                ? const Color(0xFFE5B544)
                                : const Color(0xFF999999),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // 显示卡片数据
              _buildCardDataDisplay(cardData, service),
            ],
          ],
        ),
      );
    });
  }

  /// 卡片数据显示
  Widget _buildCardDataDisplay(
    Map<String, dynamic> cardData,
    ExternalCardReaderService service,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和清除按钮
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 20.sp,
              color: const Color(0xFF52C41A),
            ),
            SizedBox(width: 8.w),
            Text(
              '读取成功',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF52C41A),
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => service.clearCardData(),
              icon: Icon(Icons.clear, size: 18.sp),
              tooltip: '清除数据',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        
        SizedBox(height: 16.h),
        const Divider(height: 1, color: Color(0xFFE8E8E8)),
        SizedBox(height: 16.h),
        
        // 卡片信息
        _buildCardInfoRow('卡片UID', cardData['uid'] ?? 'N/A'),
        SizedBox(height: 12.h),
        _buildCardInfoRow('卡片类型', cardData['type'] ?? 'N/A'),
        SizedBox(height: 12.h),
        _buildCardInfoRow('卡片容量', cardData['capacity'] ?? 'N/A'),
        SizedBox(height: 12.h),
        _buildCardInfoRow(
          '读取时间',
          cardData['timestamp'] != null
              ? _formatTimestamp(cardData['timestamp'])
              : 'N/A',
        ),
        
        if (cardData['atr'] != null) ...[
          SizedBox(height: 12.h),
          _buildCardInfoRow('ATR', cardData['atr']),
        ],
      ],
    );
  }

  /// 卡片信息行
  Widget _buildCardInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80.w,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF7F8C8D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF2C3E50),
              fontWeight: FontWeight.w500,
              fontFamily: label == 'ATR' ? 'monospace' : null,
            ),
            maxLines: label == 'ATR' ? 3 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// 格式化时间戳
  String _formatTimestamp(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }

  /// 扫描中状态
  Widget _buildScanningState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.h,
            child: const CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9C27B0)),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            '正在扫描USB设备...',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF7F8C8D),
            ),
          ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.credit_card_off,
            size: 80.sp,
            color: const Color(0xFFBDC3C7),
          ),
          SizedBox(height: 24.h),
          Text(
            '未检测到USB读卡器',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF7F8C8D),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '请连接USB读卡器后点击"扫描USB设备"',
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFFBDC3C7),
            ),
          ),
        ],
      ),
    );
  }

  /// 显示调试日志
  void _showDebugLogs(ExternalCardReaderService service) {
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
                    onPressed: () => service.clearLogs(),
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
                    itemCount: service.debugLogs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 4.h),
                        child: Text(
                          service.debugLogs[index],
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
