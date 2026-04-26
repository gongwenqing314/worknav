/// HTTP 客户端
/// Web 平台使用 dart:html HttpRequest，绕过 Dio 的 Web 兼容性问题
library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../utils/storage_util.dart';

/// 简单的 HTTP 客户端（Web 专用）
class SimpleHttpClient {
  /// GET 请求
  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    String url = '${ApiConstants.baseUrl}$path';
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final qs = queryParameters.entries
          .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}')
          .join('&');
      url += '?$qs';
    }
    return _request('GET', url);
  }

  /// POST 请求
  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final url = '${ApiConstants.baseUrl}$path';
    return _request('POST', url, body: data);
  }

  /// PUT 请求
  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final url = '${ApiConstants.baseUrl}$path';
    return _request('PUT', url, body: data);
  }

  /// DELETE 请求
  Future<Map<String, dynamic>> delete(String path) async {
    final url = '${ApiConstants.baseUrl}$path';
    return _request('DELETE', url);
  }

  /// 通用请求方法
  Future<Map<String, dynamic>> _request(String method, String url, {dynamic body}) async {
    try {
      final request = html.HttpRequest();
      request.open(method, url, async: true);

      // 设置请求头
      request.setRequestHeader('Content-Type', 'application/json');
      request.setRequestHeader('Accept', 'application/json');

      // 添加认证 Token
      final token = StorageUtil.getString(StorageUtil.keyAuthToken);
      if (token != null && token.isNotEmpty) {
        request.setRequestHeader('Authorization', 'Bearer $token');
      }

      // 发送请求
      if (body != null) {
        request.send(jsonEncode(body));
      } else {
        request.send();
      }

      // 等待响应
      await request.onLoad.first;

      if (request.status == 200 || request.status == 201) {
        final responseText = request.responseText;
        if (responseText != null && responseText.isNotEmpty) {
          return jsonDecode(responseText) as Map<String, dynamic>;
        }
        return {'code': 200, 'message': 'success', 'data': null};
      } else {
        debugPrint('HTTP $method $url 返回 ${request.status}');
        try {
          return jsonDecode(request.responseText ?? '{}') as Map<String, dynamic>;
        } catch (_) {
          return {'code': request.status, 'message': '请求失败: ${request.status}', 'data': null};
        }
      }
    } catch (e) {
      debugPrint('HTTP 请求失败: $method $url - $e');
      return {'code': -1, 'message': '网络错误: $e', 'data': null};
    }
  }
}
