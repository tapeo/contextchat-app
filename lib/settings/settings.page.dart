import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/custom_app_bar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/github_sync/github_sync_provider.dart';
import 'package:contextchat/github_sync/models/enums.dart';
import 'package:contextchat/github_sync/models/github_sync_config.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:contextchat/secure_storage/secure_storage.service.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsPage> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _storagePathController;
  late final TextEditingController _githubOwnerController;
  late final TextEditingController _githubRepoController;
  late final TextEditingController _githubBranchController;
  late final TextEditingController _githubSubdirectoryController;
  late final TextEditingController _githubTokenController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(openRouterProvider);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey ?? '');
    _storagePathController = TextEditingController(
      text: ref.read(databaseProvider).memoryPath,
    );

    final syncConfig = ref.read(githubSyncProvider).config;
    _githubOwnerController = TextEditingController(
      text: syncConfig?.owner ?? '',
    );
    _githubRepoController = TextEditingController(text: syncConfig?.repo ?? '');
    _githubBranchController = TextEditingController(
      text: syncConfig?.branch ?? 'main',
    );
    _githubSubdirectoryController = TextEditingController(
      text: syncConfig?.subdirectory ?? '',
    );
    _githubTokenController = TextEditingController();
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _storagePathController.dispose();
    _githubOwnerController.dispose();
    _githubRepoController.dispose();
    _githubBranchController.dispose();
    _githubSubdirectoryController.dispose();
    _githubTokenController.dispose();
    super.dispose();
  }

  Future<void> _saveGitHubConfig() async {
    final owner = _githubOwnerController.text.trim();
    final repo = _githubRepoController.text.trim();
    final branch = _githubBranchController.text.trim();
    final subdirectory = _githubSubdirectoryController.text.trim();
    final token = _githubTokenController.text.trim();

    if (owner.isEmpty || repo.isEmpty || branch.isEmpty) {
      showAppSnackBar(context, 'Please fill in owner, repo, and branch');
      return;
    }

    if (token.isNotEmpty) {
      await SecureStorageService.saveGithubToken(token);
    }

    final config = GithubSyncConfig(
      owner: owner,
      repo: repo,
      branch: branch,
      subdirectory: subdirectory.isEmpty ? null : subdirectory,
    );

    await ref.read(githubSyncProvider.notifier).configure(config);
    if (!mounted) return;
    showAppSnackBar(context, 'GitHub sync configuration saved');
  }

  void _save() {
    ref
        .read(openRouterProvider.notifier)
        .setSettings(
          baseUrl: _baseUrlController.text,
          apiKey: _apiKeyController.text.isEmpty
              ? null
              : _apiKeyController.text,
        );
    ref.read(openRouterModelsProvider.notifier).loadModels();

    final newPath = _storagePathController.text;
    if (newPath != ref.read(databaseProvider).memoryPath) {
      ref.read(fileStorageProvider).setString('storage_path', newPath);
    }

    showAppSnackBar(context, 'Settings saved');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPhone = Breakpoints.isPhone(context);
    final padding = isPhone ? Spacing.sm : Spacing.md;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Settings',
        actions: [
          IconButtonWidget(
            icon: const Icon(LucideIcons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(padding),
        children: [
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Provider Configuration',
                style: theme.textTheme.titleMedium,
              ),
              InputWidget(
                controller: _baseUrlController,
                labelText: 'Base URL',
                hintText: 'https://openrouter.ai/api/v1',
                labelStyle: theme.textTheme.bodySmall,
                hintStyle: theme.textTheme.bodySmall,
              ),
              InputWidget(
                controller: _apiKeyController,
                labelText: 'API Key',
                hintText: 'sk-or-v1-...',
                labelStyle: theme.textTheme.bodySmall,
                hintStyle: theme.textTheme.bodySmall,
                obscureText: true,
              ),
            ],
          ),
          SizedBox(height: Spacing.md),
          Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Database Configuration',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButtonWidget(
                    icon: const Icon(LucideIcons.folderOpen),
                    onPressed: () async {
                      final url = Uri.directory(_storagePathController.text);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url);
                      }
                    },
                    tooltip: 'Open database folder',
                  ),
                ],
              ),
              InputWidget(
                controller: _storagePathController,
                labelText: 'Storage Path',
                hintText: '/path/to/storage',
                labelStyle: theme.textTheme.bodySmall,
                hintStyle: theme.textTheme.bodySmall,
              ),
            ],
          ),
          SizedBox(height: Spacing.md),
          Consumer(
            builder: (context, ref, child) {
              final syncState = ref.watch(githubSyncProvider);

              return Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GitHub Sync', style: theme.textTheme.titleMedium),
                  InputWidget(
                    controller: _githubOwnerController,
                    labelText: 'Repository Owner',
                    hintText: 'username',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                  ),
                  InputWidget(
                    controller: _githubRepoController,
                    labelText: 'Repository Name',
                    hintText: 'my-repo',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                  ),
                  InputWidget(
                    controller: _githubBranchController,
                    labelText: 'Branch',
                    hintText: 'main',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                  ),
                  InputWidget(
                    controller: _githubSubdirectoryController,
                    labelText: 'Subdirectory (optional)',
                    hintText: 'data',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                  ),
                  InputWidget(
                    controller: _githubTokenController,
                    labelText: 'GitHub Token',
                    hintText: 'ghp_...',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                    obscureText: true,
                  ),
                  if (syncState.error != null)
                    Text(
                      'Error: ${syncState.error}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  if (syncState.status != SyncStatus.idle &&
                      syncState.status != SyncStatus.error)
                    Row(
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            syncState.progress?.displayMessage ??
                                switch (syncState.status) {
                                  SyncStatus.pulling =>
                                    'Pulling from GitHub...',
                                  SyncStatus.pushing => 'Pushing to GitHub...',
                                  SyncStatus.divergence =>
                                    'Checking for divergence...',
                                  _ => '',
                                },
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (syncState.lastSyncedAt != null)
                    Text(
                      'Last synced: ${syncState.lastSyncedAt}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ButtonWidget(
                        label: 'Save Config',
                        onPressed: _saveGitHubConfig,
                      ),

                      ButtonWidget(
                        label: syncState.status == SyncStatus.pulling
                            ? 'Pulling...'
                            : 'Pull',
                        onPressed: syncState.status == SyncStatus.pulling
                            ? null
                            : () =>
                                  ref.read(githubSyncProvider.notifier).pull(),
                      ),
                      ButtonWidget(
                        label: syncState.status == SyncStatus.pushing
                            ? 'Pushing...'
                            : 'Push',
                        onPressed: syncState.status == SyncStatus.pushing
                            ? null
                            : () =>
                                  ref.read(githubSyncProvider.notifier).push(),
                      ),
                      if (syncState.config != null)
                        ButtonWidget(
                          label: 'Clear',
                          onPressed: () => ref
                              .read(githubSyncProvider.notifier)
                              .clearConfig(),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
