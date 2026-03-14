import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter.service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final openRouterModelsProvider =
    NotifierProvider<OpenRouterModelsNotifier, OpenRouterModelsState>(
      () => OpenRouterModelsNotifier(),
    );

class OpenRouterModelsState extends Equatable {
  final List<OpenRouterModel> models;
  final bool loading;

  const OpenRouterModelsState({required this.models, this.loading = true});

  OpenRouterModelsState copyWith({
    List<OpenRouterModel>? models,
    bool? loading,
  }) {
    return OpenRouterModelsState(
      models: models ?? this.models,
      loading: loading ?? this.loading,
    );
  }

  @override
  List<Object?> get props => [models, loading];
}

class OpenRouterModelsNotifier extends Notifier<OpenRouterModelsState> {
  OpenRouterService get openRouter => ref.watch(openRouterServiceProvider);

  @override
  OpenRouterModelsState build() {
    return const OpenRouterModelsState(models: [], loading: true);
  }

  Future<void> loadModels() async {
    final settings = ref.read(openRouterProvider);
    state = state.copyWith(loading: true);
    try {
      final models = await openRouter.fetchModels(
        settings.baseUrl,
        settings.apiKey,
      );
      state = state.copyWith(models: models, loading: false);
    } catch (e) {
      state = state.copyWith(models: [], loading: false);
    }
  }
}
