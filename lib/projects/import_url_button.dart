import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/app_snackbar.dart';
import 'package:contextchat/components/button.dart';
import 'package:contextchat/components/input.dart';
import 'package:contextchat/components/text_button.dart';
import 'package:contextchat/projects/url_import.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ImportUrlButton extends ConsumerWidget {
  final void Function(String text, String source) onImported;

  const ImportUrlButton({super.key, required this.onImported});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ButtonWidget(
      onPressed: () => _showUrlDialog(context, ref),
      icon: const Icon(LucideIcons.link),
      label: 'Import from URL',
    );
  }

  Future<void> _showUrlDialog(BuildContext context, WidgetRef ref) async {
    final urlController = TextEditingController();
    final isLoading = ref.watch(urlImportProvider).isLoading;

    final url = await showAppDialog<String>(
      context: context,
      title: const Text('Import from URL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InputWidget(
            controller: urlController,
            hintText: 'https://example.com/page',
            enabled: !isLoading,
            onSubmitted: isLoading
                ? null
                : (_) => Navigator.of(context).pop(urlController.text),
          ),
          if (isLoading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
        ],
      ),
      actions: [
        TextButtonWidget(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(''),
          child: const Text('Cancel'),
        ),
        TextButtonWidget(
          onPressed: isLoading
              ? null
              : () => Navigator.of(context).pop(urlController.text),
          child: const Text('Import'),
        ),
      ],
    );

    if (url == null || url.isEmpty) {
      return;
    }

    try {
      final result = await ref
          .read(urlImportProvider.notifier)
          .importFromUrl(url);

      if (!result.isSuccess) {
        if (context.mounted) {
          showAppSnackBar(context, result.error ?? 'Failed to import from URL');
        }
        return;
      }

      onImported(result.text!, url);
    } catch (error) {
      if (context.mounted) {
        showAppSnackBar(context, 'Failed to import from URL: $error');
      }
    }
  }
}
