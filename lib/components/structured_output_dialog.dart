import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/button.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A model representing a structured output item from an AI response.
/// Uses generic key-value pairs to support any response schema.
class StructuredOutputItem {
  final String id;
  final String? category;
  final Map<String, dynamic> fields;

  const StructuredOutputItem({
    required this.id,
    this.category,
    this.fields = const {},
  });

  factory StructuredOutputItem.fromJson(Map<String, dynamic> json) {
    return StructuredOutputItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String?,
      fields: json,
    );
  }

  /// Get a field value by key
  T? getField<T>(String key) => fields[key] as T?;

  /// Get a string field value
  String? getString(String key) => fields[key]?.toString();

  /// Check if a field exists and is not empty
  bool hasField(String key) {
    final value = fields[key];
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    return true;
  }
}

/// Configuration for how to display structured output
class StructuredOutputDialogConfig {
  final String title;
  final IconData icon;
  final Color? accentColor;
  final bool showDiff;
  final bool showCategory;

  const StructuredOutputDialogConfig({
    this.title = 'Details',
    this.icon = LucideIcons.info,
    this.accentColor,
    this.showDiff = true,
    this.showCategory = true,
  });

  /// Creates a config for correction/grammar explanations
  factory StructuredOutputDialogConfig.correction() {
    return const StructuredOutputDialogConfig(
      title: 'Micro Lesson',
      icon: LucideIcons.book,
      showDiff: true,
      showCategory: true,
    );
  }

  /// Creates a config for teaching insights
  factory StructuredOutputDialogConfig.teaching() {
    return const StructuredOutputDialogConfig(
      title: 'Language Insight',
      icon: LucideIcons.lightbulb,
      showDiff: false,
      showCategory: true,
    );
  }

  /// Creates a config for general structured output
  factory StructuredOutputDialogConfig.general({
    String title = 'Details',
    IconData icon = LucideIcons.info,
  }) {
    return StructuredOutputDialogConfig(
      title: title,
      icon: icon,
      showDiff: false,
      showCategory: false,
    );
  }
}

/// Helper class to get category-based styling
class CategoryStyling {
  static Color getColor(String? category) {
    switch (category?.toLowerCase()) {
      case 'grammar':
        return Colors.blue;
      case 'vocabulary':
        return Colors.purple;
      case 'verb_tense':
        return Colors.orange;
      case 'phrasal_verb':
        return Colors.teal;
      case 'idiom':
        return Colors.pink;
      case 'spelling':
        return Colors.red;
      case 'punctuation':
        return Colors.indigo;
      case 'style':
        return Colors.cyan;
      default:
        return Colors.blue;
    }
  }

  static String formatCategory(String? category) {
    if (category == null) return '';
    return category.toUpperCase().replaceAll('_', ' ');
  }
}

/// Shows a generic dialog for displaying structured AI output
void showStructuredOutputDialog({
  required BuildContext context,
  required StructuredOutputItem item,
  StructuredOutputDialogConfig config = const StructuredOutputDialogConfig(),
  String? originalText,
  String? correctedText,
}) {
  final categoryColor =
      config.accentColor ?? CategoryStyling.getColor(item.category);

  // Use provided texts or fall back to item's fields
  final displayOriginal = originalText ?? item.getString('original') ?? '';
  final displayCorrected = correctedText ?? item.getString('corrected') ?? '';
  final showDiffSection =
      config.showDiff &&
      displayOriginal.trim().isNotEmpty &&
      displayOriginal.trim() != displayCorrected.trim();

  showAppDialog(
    context: context,
    title: Row(
      children: [
        Icon(config.icon, color: categoryColor),
        const SizedBox(width: 8),
        Text(config.title),
      ],
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category badge
        if (config.showCategory && item.category != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                CategoryStyling.formatCategory(item.category),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: categoryColor,
                ),
              ),
            ),
          ),

        // Diff display (original → corrected)
        if (showDiffSection) ...[
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayOriginal.trim(),
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
              const Icon(LucideIcons.forward, size: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayCorrected.trim(),
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // Display all fields from the item dynamically
        ..._buildFieldWidgets(item.fields, context),
      ],
    ),
    actions: [
      ButtonWidget(
        onPressed: () => Navigator.of(context).pop(),
        label: 'Got it!',
      ),
    ],
  );
}

/// Build widgets for all fields in the structured output
List<Widget> _buildFieldWidgets(
  Map<String, dynamic> fields,
  BuildContext context,
) {
  // Fields to skip in the generic display (shown separately)
  const skipFields = {'id', 'original', 'corrected', 'category'};

  final displayFields = fields.entries
      .where((e) => !skipFields.contains(e.key))
      .toList();

  if (displayFields.isEmpty) {
    return [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'No additional information available.',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ),
    ];
  }

  return displayFields.map((entry) {
    final label = _formatFieldLabel(entry.key);
    final value = entry.value;

    // Check if this is a "details" or "explanation" type field (show with special styling)
    final isDetailField =
        entry.key.toLowerCase().contains('explanation') ||
        entry.key.toLowerCase().contains('details') ||
        entry.key.toLowerCase().contains('description');

    if (isDetailField && value is String) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.lightbulb,
                color: Colors.amber.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    // Regular field display
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Expanded(
            child: Text(value.toString(), style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }).toList();
}

/// Format a field key into a human-readable label
String _formatFieldLabel(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : word,
      )
      .join(' ');
}
