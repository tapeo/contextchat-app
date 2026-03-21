import 'package:equatable/equatable.dart';

class OpenRouterState extends Equatable {
  final String? apiKey;
  final String baseUrl;

  const OpenRouterState({
    this.apiKey,
    this.baseUrl = 'https://openrouter.ai/api/v1',
  });

  OpenRouterState copyWith({String? apiKey, String? baseUrl}) {
    return OpenRouterState(
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
    );
  }

  @override
  List<Object?> get props => [apiKey, baseUrl];
}
