import 'dart:async';
import 'dart:convert';

import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final openRouterServiceProvider = Provider<OpenRouterService>((ref) {
  return OpenRouterService();
});

class OpenRouterService {
  OpenRouterService();

  Future<bool> testApiKey(String baseUrl, String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error testing API key: $e');
      return false;
    }
  }

  Stream<OpenRouterStreamChunk> send({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    required List<OpenRouterMessage> messages,
  }) async* {
    final client = http.Client();
    String? responseId;
    int? createdTimestamp;
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/chat/completions'),
      );
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      });
      request.body = jsonEncode({
        'model': modelId,
        'messages': messages.map((e) => e.toJson()).toList(),
        'stream': true,
      });

      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('Failed to stream response: ${response.statusCode}');
      }

      final stream = response.stream
          .transform(utf8.decoder)
          .transform(LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;
          try {
            final json = jsonDecode(data);
            if (responseId == null && json['id'] != null) {
              responseId = json['id'] as String;
            }
            if (createdTimestamp == null && json['created'] != null) {
              createdTimestamp = json['created'] as int;
            }
            final delta = json['choices']?[0]?['delta']?['content'];
            if (delta != null && delta.isNotEmpty) {
              yield OpenRouterStreamChunk(
                id: responseId,
                created: createdTimestamp,
                content: delta,
              );
            }
          } catch (e) {
            debugPrint('Error parsing stream data: $e');
          }
        }
      }
    } finally {
      client.close();
    }
  }

  Future<String> sendNonStreaming({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    required List<OpenRouterMessage> messages,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': modelId,
        'messages': messages.map((e) => e.toJson()).toList(),
        'stream': false,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] as String?;
      if (content != null) {
        return content.trim();
      }
    }

    throw Exception('Failed to get response: ${response.statusCode}');
  }

  Future<List<OpenRouterModel>> fetchModels(
    String baseUrl,
    String? apiKey,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/models'),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey != null) 'Authorization': 'Bearer $apiKey',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final models = (data['data'] as List)
          .map((json) => OpenRouterModel.fromJson(json))
          .toList();

      return models;
    } else {
      throw Exception('Failed to fetch models: ${response.statusCode}');
    }
  }
}
