import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NetworkDetectionView extends StatelessWidget {
  const NetworkDetectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.network_check,
            size: 80.sp,
            color: const Color(0xFFE0E0E0),
          ),
          SizedBox(height: 24.h),
          Text(
            '网络检测',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '此功能正在开发中...',
            style: TextStyle(
              fontSize: 16.sp,
              color: const Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }
}
