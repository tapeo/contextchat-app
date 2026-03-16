import 'package:collection/collection.dart';
import 'package:contextchat/chat/chat.provider.dart';
import 'package:contextchat/chat/chats.provider.dart';
import 'package:contextchat/components/app_dialog.dart';
import 'package:contextchat/components/button.widget.dart';
import 'package:contextchat/components/input.widget.dart';
import 'package:contextchat/components/list_tile.widget.dart';
import 'package:contextchat/components/text_button.widget.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/openrouter/openrouter_models.provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SelectAiModelView extends ConsumerStatefulWidget {
  const SelectAiModelView({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() {
    return _SelectAiModelViewState();
  }
}

class _SelectAiModelViewState extends ConsumerState<SelectAiModelView> {
  String formatContextLength(int length) {
    if (length >= 1000) {
      double k = length / 1000.0;
      return '${k.toStringAsFixed(k % 1 == 0 ? 0 : 1)}k tokens';
    } else {
      return '$length tokens';
    }
  }

  String formatPrice(String? price) {
    if (price == null || price.isEmpty || price == '0') {
      return 'Free';
    }
    final priceValue = double.tryParse(price);
    if (priceValue == null || priceValue == 0) {
      return 'Free';
    }
    final pricePerMillion = priceValue * 1000000;
    return '\$${pricePerMillion.toStringAsFixed(2)}/M';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String? get chatId =>
      ref.watch(chatsProvider.select((state) => state.selectedChatId));

  Future<void> _openModelPicker(
    BuildContext context,
    List<OpenRouterModel> models,
    String? selectedModelId,
  ) async {
    final pickedModelId = await showAppDialog<String>(
      context: context,
      title: const Text('Select model'),
      content: _ModelPickerDialog(
        models: models,
        selectedModelId: selectedModelId,
        formatContextLength: formatContextLength,
        formatPrice: formatPrice,
      ),
      actions: [
        TextButtonWidget(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );

    if (pickedModelId == null || chatId == null) return;
    ref.read(chatProvider(chatId!).notifier).selectModel(pickedModelId);
  }

  @override
  Widget build(BuildContext context) {
    if (chatId == null) {
      return const ButtonWidget(onPressed: null, label: 'Select Model');
    }

    final selectedModelId = ref.watch(
      chatProvider(chatId!).select((state) => state.selectedModelId),
    );

    final openRouterModelsState = ref.watch(openRouterModelsProvider);

    if (openRouterModelsState.loading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final selectedModel = openRouterModelsState.models.firstWhereOrNull(
      (model) => model.id == selectedModelId,
    );
    return ButtonWidget(
      onPressed: openRouterModelsState.models.isEmpty
          ? null
          : () => _openModelPicker(
              context,
              openRouterModelsState.models,
              selectedModelId,
            ),
      label: selectedModel?.name ?? selectedModelId ?? 'Select Model',
      size: ButtonSize.small,
    );
  }
}

class _ModelPickerDialog extends StatefulWidget {
  const _ModelPickerDialog({
    required this.models,
    required this.selectedModelId,
    required this.formatContextLength,
    required this.formatPrice,
  });

  final List<OpenRouterModel> models;
  final String? selectedModelId;
  final String Function(int) formatContextLength;
  final String Function(String?) formatPrice;

  @override
  State<_ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  late final TextEditingController _searchController;
  String? _currentSort;
  bool _isAscending = true;

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

  void _toggleSort(String sort) {
    setState(() {
      if (_currentSort == sort) {
        _isAscending = !_isAscending;
      } else {
        _currentSort = sort;
        _isAscending = true;
      }
    });
  }

  List<OpenRouterModel> get _filteredModels {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.models
        .where((model) => model.name.toLowerCase().contains(query))
        .toList();

    if (_currentSort == null) {
      return filtered;
    }

    filtered.sort((a, b) {
      int compare = 0;
      switch (_currentSort) {
        case 'price':
          final aPrice = double.tryParse(a.pricing.prompt ?? '0') ?? 0;
          final bPrice = double.tryParse(b.pricing.prompt ?? '0') ?? 0;
          compare = aPrice.compareTo(bPrice);
          break;
        case 'contextLength':
          compare = a.contextLength.compareTo(b.contextLength);
          break;
        case 'created':
          compare = a.created.compareTo(b.created);
          break;
      }
      return _isAscending ? compare : -compare;
    });

    return filtered;
  }

  Widget _buildSortButton(String sort, String label) {
    final isSelected = _currentSort == sort;

    return ButtonWidget(
      onPressed: () => _toggleSort(sort),
      label: '$label ${isSelected ? (_isAscending ? '↑' : '↓') : ''}',
      size: ButtonSize.small,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredModels = _filteredModels;

    return SizedBox(
      width: 520,
      height: 420,
      child: Column(
        children: [
          _CustomModelInput(
            onSelect: (customModelId) =>
                Navigator.of(context).pop(customModelId),
          ),
          SizedBox(height: 8),
          InputWidget(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search models',
              labelStyle: theme.textTheme.bodySmall,
              border: InputBorder.none,
              isDense: true,
            ),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSortButton('price', 'Price'),
              _buildSortButton('contextLength', 'Context'),
              _buildSortButton('created', 'Created'),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filteredModels.isEmpty
                ? const Center(child: Text('No models match your search.'))
                : ListView.builder(
                    itemCount: filteredModels.length,
                    itemBuilder: (context, index) {
                      final model = filteredModels[index];
                      return ListTileWidget(
                        selected: model.id == widget.selectedModelId,
                        title: Row(
                          children: [
                            Tooltip(
                              richMessage: WidgetSpan(
                                child: SizedBox(
                                  width: 300,
                                  child: Text(model.description),
                                ),
                              ),
                              child: Icon(
                                LucideIcons.info,
                                size: 14,
                                color: theme.iconTheme.color?.withAlpha(128),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    model.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  SelectionArea(
                                    child: Text(
                                      model.id,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withAlpha(128),
                                            fontFamily: 'monospace',
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'In: ${widget.formatPrice(model.pricing.prompt)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                Text(
                                  'Out: ${widget.formatPrice(model.pricing.completion)}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Text(
                              widget.formatContextLength(model.contextLength),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                        onTap: () => Navigator.of(context).pop(model.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomModelInput extends StatefulWidget {
  const _CustomModelInput({required this.onSelect});

  final void Function(String customModelId) onSelect;

  @override
  State<_CustomModelInput> createState() => _CustomModelInputState();
}

class _CustomModelInputState extends State<_CustomModelInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSelect() {
    final customModelId = _controller.text.trim();
    if (customModelId.isNotEmpty) {
      widget.onSelect(customModelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: InputWidget(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Custom model (e.g., provider/model-name)',
              labelStyle: theme.textTheme.bodySmall,
              border: InputBorder.none,
              isDense: true,
            ),
            style: theme.textTheme.bodySmall,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _onSelect(),
          ),
        ),
        const SizedBox(width: 8),
        ButtonWidget(
          onPressed: _controller.text.trim().isNotEmpty ? _onSelect : null,
          label: 'Use',
          size: ButtonSize.small,
        ),
      ],
    );
  }
}
