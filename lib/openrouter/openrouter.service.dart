import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
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
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
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
      final body = <String, dynamic>{
        'model': modelId,
        'messages': messages.map((e) => e.toJson()).toList(),
        'stream': true,
      };
      if (tools != null && tools.isNotEmpty) {
        body['tools'] = tools.map((tool) => tool.toJson()).toList();
      }
      if (toolChoice != null) {
        body['tool_choice'] = toolChoice.toJson();
      }
      if (parallelToolCalls != null) {
        body['parallel_tool_calls'] = parallelToolCalls;
      }
      request.body = jsonEncode(body);

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
            final choice = json['choices']?[0];
            final delta = choice?['delta']?['content'];
            final finishReason = choice?['finish_reason'] as String?;
            if (delta != null && delta.isNotEmpty) {
              yield OpenRouterStreamChunk(
                id: responseId,
                created: createdTimestamp,
                content: delta,
                finishReason: finishReason,
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
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
  }) async {
    final completion = await sendNonStreamingCompletion(
      baseUrl: baseUrl,
      apiKey: apiKey,
      modelId: modelId,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
    );

    final content = completion.choices.firstOrNull?.message.content;
    if (content != null) {
      return content.trim();
    }

    throw Exception('Failed to get text response');
  }

  Future<OpenRouterChatCompletion> sendNonStreamingCompletion({
    required String baseUrl,
    required String apiKey,
    required String modelId,
    required List<OpenRouterMessage> messages,
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
  }) async {
    final body = <String, dynamic>{
      'model': modelId,
      'messages': messages.map((e) => e.toJson()).toList(),
      'stream': false,
    };
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = tools.map((tool) => tool.toJson()).toList();
    }
    if (toolChoice != null) {
      body['tool_choice'] = toolChoice.toJson();
    }
    if (parallelToolCalls != null) {
      body['parallel_tool_calls'] = parallelToolCalls;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return OpenRouterChatCompletion.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    }

    throw Exception(
      'Failed to get response: ${response.statusCode} ${response.body}',
    );
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
