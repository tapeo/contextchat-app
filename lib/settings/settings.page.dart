import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/custom_app_bar.dart';
import 'package:contextchat/components/icon_button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/openrouter/openrouter.provider.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
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
        ],
      ),
    );
  }
}
