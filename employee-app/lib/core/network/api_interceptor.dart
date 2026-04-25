/// 认证拦截器
/// 自动在请求头中添加认证令牌，处理令牌过期刷新
library;

import 'package:dio/dio.dart';
import '../utils/storage_util.dart';

class ApiInterceptor extends Interceptor {
  final Dio _dio;

  ApiInterceptor(this._dio);

  /// 令牌存储键
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // 从本地存储读取令牌
    final token = await StorageUtil.getString(_tokenKey);
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // 处理 401 未授权错误，尝试刷新令牌
    if (err.response?.statusCode == 401) {
      try {
        final refreshToken = await StorageUtil.getString(_refreshTokenKey);
        if (refreshToken != null && refreshToken.isNotEmpty) {
          // 尝试刷新令牌
          final response = await _dio.post(
            '/api/auth/refresh-token',
            data: {'refreshToken': refreshToken},
            options: Options(headers: {'Authorization': ''}),
          );

          final newToken = response.data['accessToken'] as String?;
          final newRefreshToken = response.data['refreshToken'] as String?;

          if (newToken != null) {
            // 保存新令牌
            await StorageUtil.setString(_tokenKey, newToken);
            if (newRefreshToken != null) {
              await StorageUtil.setString(_refreshTokenKey, newRefreshToken);
            }

            // 使用新令牌重试原请求
            err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await _dio.fetch(err.requestOptions);
            handler.resolve(retryResponse);
            return;
          }
        }
      } catch (_) {
        // 刷新令牌失败，跳转到登录
      }
    }
    handler.next(err);
  }
}
