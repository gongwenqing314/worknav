/// 沟通服务
/// 获取常用语列表、管理沟通记录
library;

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/storage_util.dart';
import '../models/comm_phrase.dart';

/// 沟通服务
class CommunicationService {
  final DioClient _dioClient;

  CommunicationService(this._dioClient);

  /// 缓存键
  static const String _cacheKeyPhrases = 'cache_phrases';

  /// Web 平台 HTTP GET 请求辅助方法
  Future<Map<String, dynamic>?> _webGet(String path) async {
    final url = '${ApiConstants.baseUrl}$path';
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try { token = (jsonDecode(rawToken) as String); } catch (_) { token = rawToken; }
    }
    final request = html.HttpRequest();
    request.open('GET', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send();
    await request.onLoad.first;
    if (request.status == 200) {
      return jsonDecode(request.responseText!) as Map<String, dynamic>;
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// Web 平台 HTTP POST 请求辅助方法
  Future<Map<String, dynamic>?> _webPost(String path, {dynamic data}) async {
    final url = '${ApiConstants.baseUrl}$path';
    final rawToken = html.window.localStorage['flutter.auth_token'];
    String? token;
    if (rawToken != null && rawToken.isNotEmpty) {
      try { token = (jsonDecode(rawToken) as String); } catch (_) { token = rawToken; }
    }
    final request = html.HttpRequest();
    request.open('POST', url, async: true);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.setRequestHeader('Authorization', 'Bearer $token');
    }
    request.send(jsonEncode(data));
    await request.onLoad.first;
    if (request.status == 200 || request.status == 201) {
      if (request.responseText != null && request.responseText!.isNotEmpty) {
        return jsonDecode(request.responseText!) as Map<String, dynamic>;
      }
      return {};
    }
    throw Exception('Web request failed: ${request.status} ${request.statusText}');
  }

  /// 获取常用语列表
  /// 优先从网络获取，失败时使用默认列表
  Future<List<CommPhrase>> getPhrases() async {
    try {
      Map<String, dynamic>? data;
      if (kIsWeb) {
        data = await _webGet(ApiConstants.phrases);
      } else {
        final response = await _dioClient.get(ApiConstants.phrases);
        data = response.data;
      }

      if (data != null && data['phrases'] != null) {
        final phrases = (data['phrases'] as List)
            .map((p) => CommPhrase.fromJson(p as Map<String, dynamic>))
            .where((p) => p.isEnabled)
            .toList()
          ..sort((a, b) => a.order.compareTo(b.order));

        // 缓存到本地
        await _cachePhrases(phrases);
        return phrases;
      }
      return CommPhrase.defaultPhrases;
    } catch (e) {
      debugPrint('获取常用语失败: $e，使用默认列表');
      return _getCachedPhrases();
    }
  }

  /// 记录使用某条常用语（用于统计）
  Future<void> logPhraseUsage(String phraseId) async {
    try {
      if (kIsWeb) {
        await _webPost(
          '/api/communication/log-usage',
          data: {
            'phraseId': phraseId,
            'usedAt': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await _dioClient.post(
          '/api/communication/log-usage',
          data: {
            'phraseId': phraseId,
            'usedAt': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('记录常用语使用失败: $e');
    }
  }

  /// 缓存常用语列表
  Future<void> _cachePhrases(List<CommPhrase> phrases) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(phrases.map((p) => p.toJson()).toList());
    await prefs.setString(_cacheKeyPhrases, jsonStr);
  }

  /// 从缓存读取常用语
  List<CommPhrase> _getCachedPhrases() {
    try {
      final prefs = SharedPreferences.getInstance();
      prefs.then((p) {
        final jsonStr = p.getString(_cacheKeyPhrases);
        if (jsonStr != null) {
          final list = jsonDecode(jsonStr) as List;
          return list
              .map((p) => CommPhrase.fromJson(p as Map<String, dynamic>))
              .toList();
        }
        return CommPhrase.defaultPhrases;
      });
      return CommPhrase.defaultPhrases;
    } catch (_) {
      return CommPhrase.defaultPhrases;
    }
  }
}
