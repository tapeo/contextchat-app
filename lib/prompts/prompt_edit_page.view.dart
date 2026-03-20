import 'package:collection/collection.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/button.widget.dart';
import 'package:contextchat/components/card.widget.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/input.widget.dart';
import 'package:contextchat/components/resizable_text_area.widget.dart';
import 'package:contextchat/components/text_button.widget.dart';
import 'package:contextchat/prompts/prompts.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PromptEditPage extends ConsumerStatefulWidget {
  const PromptEditPage({super.key});

  @override
  ConsumerState<PromptEditPage> createState() => _PromptEditPageState();
}

class _PromptEditPageState extends ConsumerState<PromptEditPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _variablesController;
  late final TextEditingController _promptTextController;

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
    final promptsState = ref.read(promptsProvider);
    final selectedId = promptsState.selectedPromptId;
    if (selectedId == null) return false;
    final prompt = promptsState.prompts.firstWhereOrNull(
      (p) => p.id == selectedId,
    );
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
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    );

    return confirmed == true;
  }

  Future<void> _save() async {
    setState(() {
      _showValidation = true;
    });
    if (!_isValid || _isSaving) {
      return;
    }

    final promptsState = ref.read(promptsProvider);
    final id = promptsState.selectedPromptId;
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

  Future<void> _togglePinned() async {
    final promptsState = ref.read(promptsProvider);
    final id = promptsState.selectedPromptId;
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

  @override
  Widget build(BuildContext context) {
    final promptsState = ref.watch(promptsProvider);
    final selectedId = promptsState.selectedPromptId;
    final selectedPrompt = selectedId == null
        ? null
        : promptsState.prompts.firstWhereOrNull((p) => p.id == selectedId);
    final theme = Theme.of(context);
    final isPhone = Breakpoints.isPhone(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        () async {
          if (!await _confirmDiscardIfDirty() || !mounted) return;
          Navigator.of(context).pop();
        }();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(selectedPrompt?.name ?? 'Edit Prompt'),
          leading: IconButtonWidget(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () async {
              if (!await _confirmDiscardIfDirty() || !mounted) return;
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButtonWidget(
              tooltip: selectedPrompt?.pinned == true ? 'Unpin' : 'Pin',
              icon: Icon(
                selectedPrompt?.pinned == true
                    ? LucideIcons.pinOff
                    : LucideIcons.pin,
              ),
              onPressed: selectedId == null || _isSaving ? null : _togglePinned,
            ),
            IconButtonWidget(
              tooltip: 'Save',
              icon: const Icon(LucideIcons.save),
              onPressed: selectedId == null || _isSaving ? null : _save,
            ),
          ],
        ),
        body: selectedPrompt == null
            ? const Center(child: Text('No prompt selected'))
            : SingleChildScrollView(
                padding: isPhone ? null : const EdgeInsets.all(16),
                child: CardWidget(
                  borderColor: isPhone ? Colors.transparent : null,
                  padding: isPhone ? null : const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InputWidget(
                        controller: _nameController,
                        labelText: 'Name',
                        hintText: 'Prompt name',
                        labelStyle: theme.textTheme.bodySmall,
                        hintStyle: theme.textTheme.bodySmall,
                        errorText: _showValidation && !_isValid
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      InputWidget(
                        controller: _descriptionController,
                        labelText: 'Description',
                        hintText: 'What is this prompt for?',
                        labelStyle: theme.textTheme.bodySmall,
                        hintStyle: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      InputWidget(
                        controller: _variablesController,
                        labelText: 'Variables',
                        hintText: 'comma,separated,variables',
                        labelStyle: theme.textTheme.bodySmall,
                        hintStyle: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            _isDirty ? 'Unsaved changes' : 'Saved',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _isDirty
                                  ? theme.colorScheme.tertiary
                                  : theme.colorScheme.onSurface.withValues(
                                      alpha: 0.6,
                                    ),
                            ),
                          ),
                          const Spacer(),
                          TextButtonWidget(
                            onPressed: _isSaving ? null : _syncFromSelection,
                            child: const Text('Reset'),
                          ),
                          const SizedBox(width: 8),
                          ButtonWidget(
                            onPressed: _isSaving ? null : _save,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
