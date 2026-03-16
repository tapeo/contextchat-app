import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/card.widget.dart';
import 'package:contextchat/components/icon_button.widget.dart';
import 'package:contextchat/components/input.widget.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  late final TextEditingController _baseUrlController;
  late final TextEditingController _apiKeyController;
  late final TextEditingController _storagePathController;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(openRouterProvider);
    _baseUrlController = TextEditingController(text: settings.baseUrl);
    _apiKeyController = TextEditingController(text: settings.apiKey ?? '');
    _storagePathController = TextEditingController(
      text: ref.read(databaseProvider).memoryPath,
    );
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _storagePathController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButtonWidget(
            icon: const Icon(LucideIcons.save),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CardWidget(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Provider Configuration',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                InputWidget(
                  controller: _baseUrlController,
                  decoration: InputDecoration(
                    labelText: 'Base URL',
                    hintText: 'https://openrouter.ai/api/v1',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                ),
                const SizedBox(height: 16),
                InputWidget(
                  controller: _apiKeyController,
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-or-v1-...',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CardWidget(
            padding: const EdgeInsets.all(16),
            child: Column(
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
                const SizedBox(height: 16),
                InputWidget(
                  controller: _storagePathController,
                  decoration: InputDecoration(
                    labelText: 'Storage Path',
                    hintText: '/path/to/storage',
                    labelStyle: theme.textTheme.bodySmall,
                    hintStyle: theme.textTheme.bodySmall,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
