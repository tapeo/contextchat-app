import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/card.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/components/list_tile.dart';
import 'package:contextchat/components/resizable_text_area.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/projects/import_url_button.dart';
import 'package:contextchat/projects/project_file_types.dart';
import 'package:contextchat/projects/project_text_import.service.dart';
import 'package:contextchat/projects/projects.model.dart';
import 'package:contextchat/projects/projects.provider.dart';
import 'package:contextchat/projects/url_import.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProjectSetupPage extends ConsumerStatefulWidget {
  const ProjectSetupPage({super.key, this.projectId});

  final String? projectId;

  @override
  ConsumerState<ProjectSetupPage> createState() => _ProjectSetupViewState();
}

class _ProjectSetupViewState extends ConsumerState<ProjectSetupPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _baseContextController;
  late final String _projectId;
  late final ProjectDatabaseService _projectDatabase;
  late final ProjectTextImportService _textImportService;

  late String _initialName;
  late String _initialBaseContext;
  late List<String> _initialFileIds;

  List<ProjectFile> _files = [];
  bool _isEditMode = false;
  bool _isSaving = false;
  bool _isDirty = false;
  bool _showValidation = false;
  bool _saved = false;
  bool _projectMissing = false;

  @override
  void initState() {
    super.initState();

    _projectDatabase = ref.read(projectDatabaseProvider);
    _textImportService = ProjectTextImportService();
    _isEditMode = widget.projectId != null;
    _projectId =
        widget.projectId ?? DateTime.now().millisecondsSinceEpoch.toString();

    final project = _isEditMode
        ? ref
              .read(projectsProvider)
              .projects
              .firstWhereOrNull((p) => p.id == widget.projectId)
        : null;

    if (_isEditMode && project == null) {
      _projectMissing = true;
      _initialName = '';
      _initialBaseContext = '';
      _initialFileIds = [];
      _nameController = TextEditingController();
      _baseContextController = TextEditingController();
    } else {
      _initialName = project?.name ?? '';
      _initialBaseContext = project?.baseContext ?? '';
      _files = project?.files ?? [];
      _initialFileIds = _files.map((file) => file.id).toList();
      _nameController = TextEditingController(text: _initialName);
      _baseContextController = TextEditingController(text: _initialBaseContext);
    }

    _nameController.addListener(_updateDirtyState);
    _baseContextController.addListener(_updateDirtyState);
  }

  @override
  void dispose() {
    if (!_saved && !_isEditMode) {
      unawaited(_projectDatabase.deleteProjectStorage(_projectId));
    }
    _nameController.dispose();
    _baseContextController.dispose();
    super.dispose();
  }

  void _updateDirtyState() {
    final name = _nameController.text.trim();
    final baseContext = _baseContextController.text;
    final fileIds = _files.map((file) => file.id).toList();
    final isDirty =
        name != _initialName ||
        baseContext != _initialBaseContext ||
        !listEquals(fileIds, _initialFileIds);

    if (isDirty != _isDirty) {
      setState(() {
        _isDirty = isDirty;
      });
    }
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _delete() async {
    final confirmed = await showAppDialog<bool>(
      context: context,
      title: const Text('Delete Project'),
      content: const Text(
        'Are you sure you want to delete this project? This action cannot be undone.',
      ),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            'Delete',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(projectsProvider.notifier).deleteProject(_projectId);
      _saved = true;
      if (mounted) {
        Navigator.of(context).pop();
        showAppSnackBar(context, 'Project deleted');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to delete project: $error');
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

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditMode) {
        await ref
            .read(projectsProvider.notifier)
            .editProject(
              _projectId,
              name: _nameController.text.trim(),
              baseContext: _baseContextController.text,
              files: _files,
            );
      } else {
        await ref
            .read(projectsProvider.notifier)
            .createProjectWithFiles(
              id: _projectId,
              name: _nameController.text.trim(),
              baseContext: _baseContextController.text,
              files: _files,
            );
        await ref.read(projectsProvider.notifier).selectProject(_projectId);
        await ref.read(chatsProvider.notifier).createChat(_projectId);
        _isEditMode = true;
      }

      _saved = true;
      _initialName = _nameController.text.trim();
      _initialBaseContext = _baseContextController.text;
      _initialFileIds = _files.map((file) => file.id).toList();
      _updateDirtyState();

      if (mounted) {
        showAppSnackBar(
          context,
          _isEditMode ? 'Project updated' : 'Project created',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to save project: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: supportedProjectImageExtensions,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFiles = result.files
        .where(
          (file) => file.path != null && isSupportedImageFileName(file.name),
        )
        .toList();
    if (pickedFiles.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Only PNG, JPEG, WebP, and GIF images are supported.',
        );
      }
      return;
    }

    final files = pickedFiles.map((file) => File(file.path!)).toList();
    final displayNames = pickedFiles.map((file) => file.name).toList();

    try {
      final added = await ref
          .read(projectsProvider.notifier)
          .importProjectFiles(
            _projectId,
            files,
            displayNames: displayNames,
            updateState: _isEditMode,
          );

      setState(() {
        _files = _sortFiles([..._files, ...added]);
      });
      _updateDirtyState();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to import files: $error');
      }
    }
  }

  Future<void> _importTextFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFiles = result.files
        .where((file) => file.path != null)
        .toList();
    final imageFiles = pickedFiles
        .where((file) => isSupportedImageFileName(file.name))
        .toList();
    final textCandidates = pickedFiles
        .where((file) => !isSupportedImageFileName(file.name))
        .toList();

    if (textCandidates.isEmpty) {
      if (mounted) {
        showAppSnackBar(
          context,
          'No text-based files selected. Use Add images for image files.',
        );
      }
      return;
    }

    final imported = <ImportedProjectText>[];
    final failedFiles = <String>[];

    for (final picked in textCandidates) {
      try {
        final text = await _textImportService.extractText(File(picked.path!));
        if (text == null) {
          failedFiles.add(picked.name);
          continue;
        }

        imported.add(ImportedProjectText(fileName: picked.name, text: text));
      } catch (_) {
        failedFiles.add(picked.name);
      }
    }

    if (imported.isNotEmpty) {
      final merged = _mergeImportedTextIntoBaseContext(
        _baseContextController.text,
        imported,
      );
      _baseContextController.value = TextEditingValue(
        text: merged,
        selection: TextSelection.collapsed(offset: merged.length),
      );
    }

    if (!mounted) {
      return;
    }

    final messages = <String>[];
    if (imported.isNotEmpty) {
      messages.add(
        'Imported ${imported.length} text file${imported.length == 1 ? '' : 's'} into Base Context.',
      );
    }
    if (imageFiles.isNotEmpty) {
      messages.add(
        'Skipped ${imageFiles.length} image file${imageFiles.length == 1 ? '' : 's'}; use Add images for those.',
      );
    }
    if (failedFiles.isNotEmpty) {
      messages.add(
        'Could not extract readable text from ${failedFiles.length} file${failedFiles.length == 1 ? '' : 's'}.',
      );
    }

    showAppSnackBar(
      context,
      messages.isEmpty ? 'No readable text was imported.' : messages.join(' '),
    );
  }

  void _handleUrlImported(String text, String source) {
    final merged = _mergeImportedTextIntoBaseContext(
      _baseContextController.text,
      [ImportedProjectText(fileName: source, text: text)],
    );

    _baseContextController.value = TextEditingValue(
      text: merged,
      selection: TextSelection.collapsed(offset: merged.length),
    );

    showAppSnackBar(context, 'Imported text from URL into Base Context');
  }

  Future<void> _removeFile(ProjectFile file) async {
    try {
      if (_isEditMode) {
        await ref
            .read(projectsProvider.notifier)
            .removeProjectFile(_projectId, file);
      } else {
        await ref
            .read(projectDatabaseProvider)
            .deleteProjectFile(_projectId, file);
      }

      setState(() {
        _files = _files.where((item) => item.id != file.id).toList();
      });
      _updateDirtyState();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Failed to remove file: $error');
      }
    }
  }

  List<ProjectFile> _sortFiles(List<ProjectFile> files) {
    final sorted = [...files];
    sorted.sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
    return sorted;
  }

  String _mergeImportedTextIntoBaseContext(
    String currentContext,
    List<ImportedProjectText> importedFiles,
  ) {
    final buffer = StringBuffer(currentContext.trimRight());

    for (final imported in importedFiles) {
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer
        ..writeln('File: ${imported.fileName}')
        ..write(imported.text.trimRight());
    }

    return buffer.toString().trimRight();
  }

  @override
  Widget build(BuildContext context) {
    if (_projectMissing) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project Setup')),
        body: const Center(child: Text('Project not found.')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit' : 'New'),
        actions: [
          if (_isEditMode)
            IconButtonWidget(
              tooltip: 'Delete',
              icon: const Icon(LucideIcons.trash2),
              onPressed: _isSaving ? null : _delete,
            ),
          IconButtonWidget(
            tooltip: 'Save',
            icon: const Icon(LucideIcons.save),
            onPressed: _isDirty && !_isSaving ? _save : null,
          ),
          SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(Spacing.sm),
        children: [
          CardWidget(
            padding: EdgeInsets.all(Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Project Details', style: theme.textTheme.titleMedium),
                SizedBox(height: Spacing.sm),
                InputWidget(
                  controller: _nameController,
                  labelText: 'Project Name',
                  labelStyle: theme.textTheme.bodySmall,
                  errorText: _showValidation && !_isValid
                      ? 'Project name is required'
                      : null,
                ),
                SizedBox(height: Spacing.sm),
                ResizableTextArea(
                  controller: _baseContextController,
                  labelText: 'Base Context',
                  hintText: 'Add reusable instructions or context...',
                  initialHeight: 150,
                  minHeight: 100,
                  maxHeight: 500,
                  textStyle: theme.textTheme.bodySmall,
                ),
                SizedBox(height: Spacing.sm),
                Text(
                  'Import PDFs, docs, code, and other readable text files directly into Base Context.',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: Spacing.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ButtonWidget(
                      onPressed: _isSaving ? null : _importTextFiles,
                      icon: const Icon(LucideIcons.notebook),
                      label: 'Import text files',
                    ),
                    ImportUrlButton(
                      onImported: (text, source) {
                        _handleUrlImported(text, source);
                      },
                    ),
                  ],
                ),
                if (ref.watch(urlImportProvider).isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          SizedBox(height: Spacing.sm),
          CardWidget(
            padding: EdgeInsets.all(Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Reference Images',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    ButtonWidget(
                      onPressed: _isSaving ? null : _addFiles,
                      icon: const Icon(LucideIcons.file),
                      label: 'Add images',
                    ),
                  ],
                ),
                SizedBox(height: Spacing.xs),
                Text(
                  'Supported: PNG, JPEG, WebP, GIF',
                  style: theme.textTheme.bodySmall,
                ),
                SizedBox(height: Spacing.sm),
                if (_files.isEmpty)
                  const Text('No images imported yet.')
                else
                  Column(
                    children: [
                      for (final file in _files)
                        ListTileWidget(
                          padding: EdgeInsets.zero,
                          leading: const Icon(LucideIcons.image, size: 32),
                          title: Text(file.name),
                          subtitle: Text('${file.sizeBytes} bytes'),
                          trailing: IconButtonWidget(
                            tooltip: 'Remove',
                            icon: const Icon(LucideIcons.delete),
                            onPressed: _isSaving
                                ? null
                                : () => _removeFile(file),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: Spacing.sm),
          if (_isDirty)
            Text(
              _isSaving ? 'Saving...' : 'Unsaved changes',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
        ],
      ),
    );
  }
}
