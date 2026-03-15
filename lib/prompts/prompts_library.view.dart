import 'package:collection/collection.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/card.widget.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/input.widget.dart';
import 'package:contextchat/components/list_tile.widget.dart';
import 'package:contextchat/components/resizable_text_area.widget.dart';
import 'package:contextchat/prompts/prompts.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PromptsLibraryView extends ConsumerStatefulWidget {
  const PromptsLibraryView({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  ConsumerState<PromptsLibraryView> createState() => _PromptsLibraryViewState();
}

class _PromptsLibraryViewState extends ConsumerState<PromptsLibraryView> {
  late final TextEditingController _searchController;
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _variablesController;
  late final TextEditingController _promptTextController;

  String? _editingPromptId;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _showValidation = false;

  String _initialName = '';
  String _initialDescription = '';
  String _initialVariables = '';
  String _initialPromptText = '';
  bool _initialPinned = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _variablesController = TextEditingController();
    _promptTextController = TextEditingController();

    _nameController.addListener(_updateDirtyState);
    _descriptionController.addListener(_updateDirtyState);
    _variablesController.addListener(_updateDirtyState);
    _promptTextController.addListener(_updateDirtyState);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromSelection();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _variablesController.dispose();
    _promptTextController.dispose();
    super.dispose();
  }

  void _syncFromSelection() {
    final promptsState = ref.read(promptsProvider);
    final selectedId = promptsState.selectedPromptId;
    final prompt = selectedId == null
        ? null
        : promptsState.prompts.firstWhereOrNull((p) => p.id == selectedId);

    setState(() {
      _editingPromptId = prompt?.id;
      _initialName = prompt?.name ?? '';
      _initialDescription = prompt?.description ?? '';
      _initialVariables = (prompt?.variables ?? const []).join(', ');
      _initialPromptText = prompt?.promptText ?? '';
      _initialPinned = prompt?.pinned ?? false;

      _nameController.text = _initialName;
      _descriptionController.text = _initialDescription;
      _variablesController.text = _initialVariables;
      _promptTextController.text = _initialPromptText;
      _isDirty = false;
      _showValidation = false;
    });
  }

  void _updateDirtyState() {
    final currentPinned = _currentPinned;
    final isDirty =
        _nameController.text.trim() != _initialName ||
        _descriptionController.text.trim() != _initialDescription ||
        _variablesController.text.trim() != _initialVariables ||
        _promptTextController.text != _initialPromptText ||
        currentPinned != _initialPinned;

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  bool get _currentPinned {
    final id = _editingPromptId;
    if (id == null) return false;
    final prompt = ref
        .read(promptsProvider)
        .prompts
        .firstWhereOrNull((p) => p.id == id);
    return prompt?.pinned ?? false;
  }

  List<String> _parseVariables(String raw) {
    return raw
        .split(',')
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_isDirty) return true;

    final confirmed = await showAppDialog<bool>(
      context: context,
      title: const Text('Discard changes?'),
      content: const Text(
        'You have unsaved changes. Discard them and continue?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    );

    return confirmed == true;
  }

  Future<void> _selectPrompt(String id) async {
    if (!await _confirmDiscardIfDirty() || !mounted) return;
    ref.read(promptsProvider.notifier).selectPrompt(id);
    _syncFromSelection();
  }

  Future<void> _createPrompt() async {
    if (!await _confirmDiscardIfDirty() || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final id = await ref
          .read(promptsProvider.notifier)
          .createPrompt(name: 'Untitled prompt', promptText: '');
      ref.read(promptsProvider.notifier).selectPrompt(id);
      _syncFromSelection();
      if (mounted) {
        showAppSnackBar(context, 'Prompt created');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to create prompt: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _showValidation = true;
    });
    if (!_isValid || _isSaving) {
      return;
    }

    final id = _editingPromptId;
    if (id == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(promptsProvider.notifier)
          .updatePrompt(
            id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            promptText: _promptTextController.text,
            variables: _parseVariables(_variablesController.text),
          );

      final prompt = ref
          .read(promptsProvider)
          .prompts
          .firstWhereOrNull((p) => p.id == id);
      if (prompt != null) {
        _initialName = prompt.name;
        _initialDescription = prompt.description;
        _initialVariables = prompt.variables.join(', ');
        _initialPromptText = prompt.promptText;
        _initialPinned = prompt.pinned;
      } else {
        _initialName = _nameController.text.trim();
        _initialDescription = _descriptionController.text.trim();
        _initialVariables = _variablesController.text.trim();
        _initialPromptText = _promptTextController.text;
      }
      _updateDirtyState();

      if (mounted) {
        showAppSnackBar(context, 'Prompt saved');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save prompt: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final id = _editingPromptId;
    if (id == null) return;

    final confirmed = await showAppDialog<bool>(
      context: context,
      title: const Text('Delete Prompt'),
      content: const Text(
        'Are you sure you want to delete this prompt? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(promptsProvider.notifier).deletePrompt(id);
      _syncFromSelection();
      if (mounted) {
        showAppSnackBar(context, 'Prompt deleted');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to delete prompt: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _togglePinned() async {
    final id = _editingPromptId;
    if (id == null || _isSaving) return;
    try {
      await ref.read(promptsProvider.notifier).togglePinned(id);
      final nextPinned = _currentPinned;
      setState(() {
        _initialPinned = nextPinned;
      });
      _updateDirtyState();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to update pin: $error');
      }
    }
  }

  Future<void> _copyPrompt() async {
    final id = _editingPromptId;
    if (id == null) return;
    final prompt = ref
        .read(promptsProvider)
        .prompts
        .firstWhereOrNull((p) => p.id == id);
    if (prompt == null) return;

    await Clipboard.setData(ClipboardData(text: prompt.promptText));
    if (mounted) {
      showAppSnackBar(context, 'Prompt copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    final promptsState = ref.watch(promptsProvider);
    final theme = Theme.of(context);

    final query = _searchController.text.trim().toLowerCase();
    final prompts = query.isEmpty
        ? promptsState.prompts
        : promptsState.prompts.where((prompt) {
            final haystack =
                '${prompt.name}\n${prompt.description}\n${prompt.variables.join(', ')}'
                    .toLowerCase();
            return haystack.contains(query);
          }).toList();

    final selectedId = promptsState.selectedPromptId;
    final selectedPrompt = selectedId == null
        ? null
        : promptsState.prompts.firstWhereOrNull((p) => p.id == selectedId);

    if (widget.pickMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Select prompt')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: CardWidget(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                InputWidget(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search',
                    hintText: 'Filter prompts…',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: prompts.isEmpty
                      ? const Center(child: Text('No prompts'))
                      : ListView.separated(
                          itemCount: prompts.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final prompt = prompts[index];
                            return ListTileWidget(
                              style: ListTileStyle2.dense,
                              leading: Icon(
                                prompt.pinned
                                    ? LucideIcons.pin
                                    : LucideIcons.fileText,
                              ),
                              title: Text(prompt.name),
                              subtitle: prompt.description.trim().isEmpty
                                  ? Text(
                                      '${prompt.variables.length} variable(s)',
                                    )
                                  : Text(prompt.description),
                              onTap: () {
                                Navigator.of(context).pop(prompt.promptText);
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final navigator = Navigator.of(context);
        () async {
          if (!await _confirmDiscardIfDirty() || !mounted) return;
          navigator.pop();
        }();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Prompts'),
          actions: [
            IconButtonWidget(
              tooltip: 'New prompt',
              icon: const Icon(LucideIcons.plus),
              onPressed: _isSaving ? null : _createPrompt,
            ),
            IconButtonWidget(
              tooltip: 'Copy prompt',
              icon: const Icon(LucideIcons.copy),
              onPressed: selectedPrompt != null && !_isSaving
                  ? _copyPrompt
                  : null,
            ),
            IconButtonWidget(
              tooltip: 'Save',
              icon: const Icon(LucideIcons.save),
              onPressed: _editingPromptId == null || _isSaving ? null : _save,
            ),
            IconButtonWidget(
              tooltip: selectedPrompt?.pinned == true ? 'Unpin' : 'Pin',
              icon: Icon(
                selectedPrompt?.pinned == true
                    ? LucideIcons.pinOff
                    : LucideIcons.pin,
              ),
              onPressed: _editingPromptId == null || _isSaving
                  ? null
                  : _togglePinned,
            ),
            IconButtonWidget(
              tooltip: 'Delete',
              icon: const Icon(LucideIcons.trash2),
              onPressed: _editingPromptId == null || _isSaving ? null : _delete,
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Row(
            children: [
              SizedBox(
                width: 340,
                child: CardWidget(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      InputWidget(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search',
                          hintText: 'Filter prompts…',
                          labelStyle: theme.textTheme.bodySmall,
                          hintStyle: theme.textTheme.bodySmall,
                          border: InputBorder.none,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: prompts.isEmpty
                            ? const Center(child: Text('No prompts'))
                            : ListView.separated(
                                itemCount: prompts.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final prompt = prompts[index];
                                  final isSelected = prompt.id == selectedId;
                                  return ListTileWidget(
                                    selected: isSelected,
                                    style: ListTileStyle2.dense,
                                    leading: Icon(
                                      prompt.pinned
                                          ? LucideIcons.pin
                                          : LucideIcons.fileText,
                                    ),
                                    title: Text(prompt.name),
                                    subtitle: prompt.description.trim().isEmpty
                                        ? Text(
                                            '${prompt.variables.length} variable(s)',
                                          )
                                        : Text(prompt.description),
                                    onTap: () => _selectPrompt(prompt.id),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: selectedPrompt == null
                    ? const Center(child: Text('Select a prompt to edit'))
                    : CardWidget(
                        padding: const EdgeInsets.all(16),
                        child: ListView(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InputWidget(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Name',
                                      hintText: 'Prompt name',
                                      labelStyle: theme.textTheme.bodySmall,
                                      hintStyle: theme.textTheme.bodySmall,
                                      border: InputBorder.none,
                                      errorText: _showValidation && !_isValid
                                          ? 'Name is required'
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButtonWidget(
                                  tooltip: selectedPrompt.pinned
                                      ? 'Unpin'
                                      : 'Pin',
                                  icon: Icon(
                                    selectedPrompt.pinned
                                        ? LucideIcons.pinOff
                                        : LucideIcons.pin,
                                  ),
                                  onPressed: _isSaving ? null : _togglePinned,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            InputWidget(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'What is this prompt for?',
                                labelStyle: theme.textTheme.bodySmall,
                                hintStyle: theme.textTheme.bodySmall,
                                border: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                            InputWidget(
                              controller: _variablesController,
                              decoration: InputDecoration(
                                labelText: 'Variables',
                                hintText: 'comma,separated,variables',
                                labelStyle: theme.textTheme.bodySmall,
                                hintStyle: theme.textTheme.bodySmall,
                                border: InputBorder.none,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Prompt', style: theme.textTheme.titleSmall),
                            const SizedBox(height: 8),
                            ResizableTextArea(
                              controller: _promptTextController,
                              hintText: 'Write your prompt here…',
                              initialHeight: 220,
                              maxHeight: 800,
                              minHeight: 140,
                              textStyle: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text(
                                  _isDirty ? 'Unsaved changes' : 'Saved',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: _isDirty
                                        ? theme.colorScheme.tertiary
                                        : theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: _isSaving
                                      ? null
                                      : () => _syncFromSelection(),
                                  child: const Text('Reset'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _isSaving ? null : _save,
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
