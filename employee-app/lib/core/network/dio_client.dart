/// Dio 网络客户端
/// 封装 Dio 实例，统一配置基础参数、超时、拦截器
library;

import 'package:dio/dio.dart';
import 'package:dio/browser.dart';
import 'package:flutter/foundation.dart';
import 'api_interceptor.dart';
import '../constants/api_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: ApiConstants.connectTimeout),
        receiveTimeout: const Duration(seconds: ApiConstants.receiveTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Web 平台使用 BrowserHttpClientAdapter
    if (kIsWeb) {
      _dio.httpClientAdapter = BrowserHttpClientAdapter(withCredentials: false);
    }

    // 添加认证拦截器
    _dio.interceptors.add(ApiInterceptor(_dio));
  }

  /// 获取 Dio 实例
  Dio get dio => _dio;

  /// GET 请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// POST 请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  /// PUT 请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE 请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// 上传文件
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraFields,
    ProgressCallback? onSendProgress,
  }) {
    final formData = FormData.fromMap({
      fieldName: MultipartFile.fromFileSync(filePath),
      if (extraFields != null) ...extraFields,
    });

    return _dio.post<T>(
      path,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
      onSendProgress: onSendProgress,
    );
  }
}
