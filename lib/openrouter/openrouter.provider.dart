import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.service.dart';
import 'package:contextchat/openrouter/openrouter.state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _apiKeyPref = 'openrouter_api_key';
const String _baseUrlPref = 'openrouter_base_url';
const String _modelIdPref = 'openrouter_model_id';
const String _toolsEnabledPref = 'openrouter_tools_enabled';

final openRouterProvider =
    NotifierProvider<OpenRouterNotifier, OpenRouterState>(
      () => OpenRouterNotifier(),
    );

class OpenRouterNotifier extends Notifier<OpenRouterState> {
  FileStorage get fileStorage => ref.watch(fileStorageProvider);
  OpenRouterService get openRouter => ref.watch(openRouterServiceProvider);

  @override
  OpenRouterState build() {
    final String? apiKey = fileStorage.getString(_apiKeyPref);
    final String? baseUrl = fileStorage.getString(_baseUrlPref);
    final String? modelId = fileStorage.getString(_modelIdPref);
    final bool toolsEnabled = fileStorage.getBool(_toolsEnabledPref) ?? true;

    return OpenRouterState(
      apiKey: apiKey,
      baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
      modelId: modelId,
      toolsEnabled: toolsEnabled,
    );
  }

  Future<void> setSettings({
    String? apiKey,
    required String baseUrl,
    String? modelId,
    bool? toolsEnabled,
  }) async {
    state = state.copyWith(
      apiKey: apiKey,
      baseUrl: baseUrl,
      modelId: modelId,
      toolsEnabled: toolsEnabled,
    );

    if (apiKey != null) {
      await fileStorage.setString(_apiKeyPref, apiKey);
    } else {
      await fileStorage.remove(_apiKeyPref);
    }

    await fileStorage.setString(_baseUrlPref, baseUrl);

    if (modelId != null) {
      await fileStorage.setString(_modelIdPref, modelId);
    } else {
      await fileStorage.remove(_modelIdPref);
    }

    await fileStorage.setBool(_toolsEnabledPref, state.toolsEnabled);
  }

  Future<void> logout() async {
    await fileStorage.remove(_apiKeyPref);
    state = state.copyWith(apiKey: null);
  }

  Stream<OpenRouterStreamChunk> send({
    required List<OpenRouterMessage> messages,
    String? modelId,
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
    ImageModalities? modalities,
    ImageConfig? imageConfig,
  }) {
    final effectiveModelId = modelId ?? state.modelId;
    if (effectiveModelId == null) {
      throw Exception('No model selected');
    }
    if (state.apiKey == null) {
      throw Exception('No API key provided');
    }

    return openRouter.send(
      baseUrl: state.baseUrl,
      apiKey: state.apiKey!,
      modelId: effectiveModelId,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      modalities: modalities,
      imageConfig: imageConfig,
    );
  }

  Future<String> sendNonStreaming({
    required List<OpenRouterMessage> messages,
    String? modelId,
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
    ImageModalities? modalities,
    ImageConfig? imageConfig,
  }) async {
    final effectiveModelId = modelId ?? state.modelId;
    if (effectiveModelId == null) {
      throw Exception('No model selected');
    }
    if (state.apiKey == null) {
      throw Exception('No API key provided');
    }

    return openRouter.sendNonStreaming(
      baseUrl: state.baseUrl,
      apiKey: state.apiKey!,
      modelId: effectiveModelId,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      modalities: modalities,
      imageConfig: imageConfig,
    );
  }

  Future<OpenRouterChatCompletion> sendCompletionNonStreaming({
    required List<OpenRouterMessage> messages,
    String? modelId,
    List<OpenRouterToolDefinition>? tools,
    OpenRouterToolChoice? toolChoice,
    bool? parallelToolCalls,
    ImageModalities? modalities,
    ImageConfig? imageConfig,
  }) async {
    final effectiveModelId = modelId ?? state.modelId;
    if (effectiveModelId == null) {
      throw Exception('No model selected');
    }
    if (state.apiKey == null) {
      throw Exception('No API key provided');
    }

    return openRouter.sendNonStreamingCompletion(
      baseUrl: state.baseUrl,
      apiKey: state.apiKey!,
      modelId: effectiveModelId,
      messages: messages,
      tools: tools,
      toolChoice: toolChoice,
      parallelToolCalls: parallelToolCalls,
      modalities: modalities,
      imageConfig: imageConfig,
    );
  }
}
