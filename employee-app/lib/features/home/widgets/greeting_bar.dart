/// 问候栏组件
/// 显示当前时间和个性化问候语
library;

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_dimensions.dart';

/// 问候栏
/// 根据当前时间显示不同的问候语
class GreetingBar extends StatelessWidget {
  /// 员工姓名
  final String? employeeName;
  /// 同步状态文字
  final String? syncStatus;

  const GreetingBar({
    super.key,
    this.employeeName,
    this.syncStatus,
  });

  /// 根据时间获取问候语
  String _getGreeting() {
    final hour = DateTime.now().hour;
    final name = employeeName ?? '同学';

    if (hour < 6) {
      return '夜深了，$name，注意休息。';
    } else if (hour < 9) {
      return '早上好，$name！';
    } else if (hour < 12) {
      return '上午好，$name！';
    } else if (hour < 14) {
      return '中午好，$name！';
    } else if (hour < 18) {
      return '下午好，$name！';
    } else {
      return '晚上好，$name！';
    }
  }

  /// 获取当前日期字符串
  String _getDateStr() {
    final now = DateTime.now();
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    return '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pagePadding,
        vertical: AppDimensions.spacingMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 问候语
          Text(
            _getGreeting(),
            style: AppTextStyles.greeting,
          ),
          const SizedBox(height: 4),
          // 日期和同步状态
          Row(
            children: [
              Text(
                _getDateStr(),
                style: AppTextStyles.bodySmall,
              ),
              if (syncStatus != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: syncStatus == '离线'
                        ? AppColors.primaryRed.withOpacity(0.1)
                        : AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        syncStatus == '离线'
                            ? Icons.wifi_off
                            : Icons.cloud_done,
                        size: 14,
                        color: syncStatus == '离线'
                            ? AppColors.primaryRed
                            : AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        syncStatus!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: syncStatus == '离线'
                              ? AppColors.primaryRed
                              : AppColors.primaryGreen,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
