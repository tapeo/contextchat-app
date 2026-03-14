import 'package:equatable/equatable.dart';

class OpenRouterState extends Equatable {
  final String? apiKey;
  final String baseUrl;
  final String? modelId;

  const OpenRouterState({
    this.apiKey,
    this.baseUrl = 'https://openrouter.ai/api/v1',
    this.modelId,
  });

  OpenRouterState copyWith({
    String? apiKey,
    String? baseUrl,
    String? modelId,
  }) {
    return OpenRouterState(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      modelId: modelId ?? this.modelId,
    );
  }

  @override
  List<Object?> get props => [apiKey, baseUrl, modelId];
}
