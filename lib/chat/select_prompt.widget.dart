import 'package:collection/collection.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/components/list_tile.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/prompts/prompt.model.dart';
import 'package:contextchat/prompts/prompts.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectPromptWidget extends ConsumerStatefulWidget {
  const SelectPromptWidget({super.key, required this.onPicked});

  final ValueChanged<String> onPicked;

  @override
  ConsumerState<SelectPromptWidget> createState() => _SelectPromptViewState();
}

class _SelectPromptViewState extends ConsumerState<SelectPromptWidget> {
  Future<void> _openPromptPicker(BuildContext context) async {
    final promptsState = ref.read(promptsProvider);
    final pickedPromptId = await showAppDialog<String>(
      context: context,
      title: const Text('Select prompt'),
      content: _PromptPickerDialog(
        prompts: promptsState.prompts,
        selectedPromptId: promptsState.selectedPromptId,
      ),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );

    if (pickedPromptId == null) return;
    final prompt = ref
        .read(promptsProvider)
        .prompts
        .firstWhereOrNull((p) => p.id == pickedPromptId);
    if (prompt == null) return;
    widget.onPicked(prompt.promptText);
  }

  @override
  Widget build(BuildContext context) {
    final promptsState = ref.watch(promptsProvider);

    return ButtonWidget(
      onPressed: promptsState.prompts.isEmpty
          ? null
          : () => _openPromptPicker(context),
      label: 'Prompts',
      size: ButtonSize.small,
    );
  }
}

class _PromptPickerDialog extends StatefulWidget {
  const _PromptPickerDialog({
    required this.prompts,
    required this.selectedPromptId,
  });

  final List<Prompt> prompts;
  final String? selectedPromptId;

  @override
  State<_PromptPickerDialog> createState() => _PromptPickerDialogState();
}

class _PromptPickerDialogState extends State<_PromptPickerDialog> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Prompt> get _filteredPrompts {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.prompts.where((prompt) {
      final haystack =
          '${prompt.name}\n${prompt.description}\n${prompt.variables.join(', ')}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredPrompts = _filteredPrompts;
    final isPhone = Breakpoints.isPhone(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: isPhone ? MediaQuery.sizeOf(context).height * 0.7 : 420,
      ),
      child: Column(
        children: [
          InputWidget(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            labelText: 'Search prompts',
            labelStyle: theme.textTheme.bodySmall,
            prefixIcon: const Icon(LucideIcons.search),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredPrompts.isEmpty
                ? const Center(child: Text('No prompts match your search.'))
                : ListView.builder(
                    itemCount: filteredPrompts.length,
                    itemBuilder: (context, index) {
                      final prompt = filteredPrompts[index];
                      return ListTileWidget(
                        selected: prompt.id == widget.selectedPromptId,
                        leading: Icon(
                          prompt.pinned
                              ? LucideIcons.pin
                              : LucideIcons.fileText,
                        ),
                        title: Text(
                          prompt.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          prompt.description.trim().isEmpty
                              ? '${prompt.variables.length} variable(s)'
                              : '${prompt.description}${prompt.variables.isNotEmpty ? ' • ${prompt.variables.length} variable(s)' : ''}',
                          maxLines: isPhone ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: isPhone
                            ? ListTileStyle2.compact
                            : ListTileStyle2.normal,
                        onTap: () => Navigator.of(context).pop(prompt.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
