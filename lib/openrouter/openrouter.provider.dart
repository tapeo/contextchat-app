import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.service.dart';
import 'package:contextchat/openrouter/openrouter.state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const String _apiKeyPref = 'openrouter_api_key';
const String _baseUrlPref = 'openrouter_base_url';
const String _modelIdPref = 'openrouter_model_id';

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

    return OpenRouterState(
      apiKey: apiKey,
      baseUrl: baseUrl ?? 'https://openrouter.ai/api/v1',
      modelId: modelId,
    );
  }

  Future<void> setSettings({
    String? apiKey,
    required String baseUrl,
    String? modelId,
  }) async {
    state = state.copyWith(apiKey: apiKey, baseUrl: baseUrl, modelId: modelId);

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
  }

  Future<void> logout() async {
    await fileStorage.remove(_apiKeyPref);
    state = state.copyWith(apiKey: null);
  }

  Stream<OpenRouterStreamChunk> send({
    required List<OpenRouterMessage> messages,
    String? modelId,
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
    );
  }
}
