import 'package:contextchat/prompts/prompt.model.dart';
import 'package:equatable/equatable.dart';

const _selectedPromptIdUnset = Object();

class PromptsState extends Equatable {
  final List<Prompt> prompts;
  final String? selectedPromptId;

  const PromptsState({required this.prompts, this.selectedPromptId});

  PromptsState copyWith({
    List<Prompt>? prompts,
    Object? selectedPromptId = _selectedPromptIdUnset,
  }) {
    return PromptsState(
      prompts: prompts ?? this.prompts,
      selectedPromptId: identical(selectedPromptId, _selectedPromptIdUnset)
          ? this.selectedPromptId
          : selectedPromptId as String?,
    );
  }

  @override
  List<Object?> get props => [prompts, selectedPromptId];
}

