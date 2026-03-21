import 'package:equatable/equatable.dart';

class OpenRouterState extends Equatable {
  final String? apiKey;
  final String baseUrl;
  final String? modelId;
  final bool toolsEnabled;

  const OpenRouterState({
    this.apiKey,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.modelId,
    this.toolsEnabled = false,
  });

  OpenRouterState copyWith({
    String? apiKey,
    String? baseUrl,
    String? modelId,
    bool? toolsEnabled,
  }) {
    return OpenRouterState(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelId: modelId ?? this.modelId,
      toolsEnabled: toolsEnabled ?? this.toolsEnabled,
    );
  }

  @override
  List<Object?> get props => [apiKey, baseUrl, modelId, toolsEnabled];
}
