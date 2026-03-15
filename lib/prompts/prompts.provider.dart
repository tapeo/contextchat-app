import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/database/prompt_database.service.dart';
import 'package:contextchat/prompts/prompt.model.dart';
import 'package:contextchat/prompts/prompts.state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final promptsProvider = NotifierProvider<PromptsNotifier, PromptsState>(
  () => PromptsNotifier(),
);

class PromptsNotifier extends Notifier<PromptsState> {
  PromptDatabaseService get databaseService => ref.watch(promptDatabaseProvider);

  @override
  PromptsState build() {
    return const PromptsState(prompts: []);
  }

  Future<void> initialize() async {
    final prompts = await databaseService.getAllPrompts();
    state = state.copyWith(prompts: _sortPrompts(prompts));
  }

  void selectPrompt(String? id) {
    state = state.copyWith(selectedPromptId: id);
  }

  Future<String> createPrompt({
    required String name,
    String description = '',
    required String promptText,
    List<String> variables = const [],
    bool pinned = false,
  }) async {
    final now = DateTime.now().toUtc();
    final id = now.millisecondsSinceEpoch.toString();
    final prompt = Prompt(
      id: id,
      name: name,
      description: description,
      promptText: promptText,
      variables: _normalizeVariables(variables),
      pinned: pinned,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(prompts: _sortPrompts([...state.prompts, prompt]));
    await databaseService.savePrompt(prompt);
    return id;
  }

  Future<void> updatePrompt(
    String id, {
    String? name,
    String? description,
    String? promptText,
    List<String>? variables,
    bool? pinned,
  }) async {
    Prompt? updatedPrompt;

    final updated = state.prompts.map((p) {
      if (p.id != id) {
        return p;
      }
      final now = DateTime.now().toUtc();
      final next = p.copyWith(
        name: name,
        description: description,
        promptText: promptText,
        variables: variables != null ? _normalizeVariables(variables) : null,
        pinned: pinned,
        updatedAt: now,
      );
      updatedPrompt = next;
      return next;
    }).toList();

    state = state.copyWith(prompts: _sortPrompts(updated));

    if (updatedPrompt != null) {
      await databaseService.savePrompt(updatedPrompt!);
    }
  }

  Future<void> deletePrompt(String id) async {
    state = state.copyWith(
      prompts: state.prompts.where((p) => p.id != id).toList(),
      selectedPromptId: state.selectedPromptId == id
          ? null
          : state.selectedPromptId,
    );
    await databaseService.deletePrompt(id);
  }

  Future<void> togglePinned(String id) async {
    final prompt = state.prompts.firstWhere((p) => p.id == id);
    await updatePrompt(id, pinned: !prompt.pinned);
  }

  List<String> _normalizeVariables(List<String> variables) {
    final normalized = <String>[];
    for (final variable in variables) {
      final trimmed = variable.trim();
      if (trimmed.isEmpty) continue;
      if (normalized.contains(trimmed)) continue;
      normalized.add(trimmed);
    }
    return normalized;
  }

  List<Prompt> _sortPrompts(List<Prompt> prompts) {
    final sorted = [...prompts];
    sorted.sort((left, right) {
      if (left.pinned != right.pinned) {
        return left.pinned ? -1 : 1;
      }
      final nameCompare = left.name.toLowerCase().compareTo(
        right.name.toLowerCase(),
      );
      if (nameCompare != 0) {
        return nameCompare;
      }
      final createdCompare = left.createdAt.compareTo(right.createdAt);
      if (createdCompare != 0) {
        return createdCompare;
      }
      return left.id.compareTo(right.id);
    });
    return sorted;
  }
}

