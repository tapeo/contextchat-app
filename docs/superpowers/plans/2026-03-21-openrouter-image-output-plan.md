# OpenRouter Image Output Support - Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add end-to-end image generation support via OpenRouter API - capability detection, composer controls, request/response handling, and chat rendering.

**Architecture:** Add `supportsImageOutput` getter to `OpenRouterModel`, create image domain models (`AssistantImage`), extend request/response structures, wire image params through provider/service, add conditional UI controls in composer, and render images in message widget.

**Tech Stack:** Flutter/Riverpod, Dart

---

## File Inventory

| File | Responsibility |
|------|----------------|
| `lib/openrouter/openrouter.model.dart` | Capability getter, request/response models |
| `lib/chat/message.model.dart` | Add `AssistantImage`, extend `Message` with `images` |
| `lib/chat/chat.model.dart` | Update `toJson`/`fromJson` for message images |
| `lib/database/chat_database.service.dart` | Serialize/deserialize message images |
| `lib/openrouter/openrouter.service.dart` | Accept image params in `send` methods |
| `lib/openrouter/openrouter.provider.dart` | Pass image params from chat provider |
| `lib/chat/chat.provider.dart` | Build image request fields, handle image responses |
| `lib/chat/composer.widget.dart` | Add image output controls (conditional) |
| `lib/chat/chat.page.dart` | Pass model capability to composer |
| `lib/chat/select_ai_model.dialog.dart` | Add image-capable filter toggle |
| `lib/chat/message.widget.dart` | Render assistant images |

---

## Task 1: Phase 1 - Capability & Model/Data Foundation

### 1.1: Add `supportsImageOutput` getter to `OpenRouterModel`

**File:** `lib/openrouter/openrouter.model.dart:445-447`

- [ ] **Step 1: Add getter after `supportsImageInput`**

```dart
bool get supportsImageOutput => architecture.outputModalities.any(
  (modality) => modality.toLowerCase() == 'image',
);
```

### 1.2: Add `AssistantImage` and `ImageModalities` models

**File:** `lib/openrouter/openrouter.model.dart`

- [ ] **Step 1: Add after existing imports**

```dart
enum ImageModalities {
  textOnly('text'),
  imageOnly('image'),
  imagePlusText('image', 'text');

  final List<String> modalities;
  const ImageModalities(this.modalities);
}

class AssistantImage extends Equatable {
  final String base64Data;
  final String mimeType;

  const AssistantImage({
    required this.base64Data,
    required this.mimeType,
  });

  factory AssistantImage.fromJson(Map<String, dynamic> json) {
    return AssistantImage(
      base64Data: json['data'] as String,
      mimeType: json['mimeType'] as String? ?? 'image/png',
    );
  }

  Map<String, dynamic> toJson() => {
    'data': base64Data,
    'mimeType': mimeType,
  };

  @override
  List<Object?> get props => [base64Data, mimeType];
}
```

### 1.3: Extend `OpenRouterStreamChunk` for image deltas

**File:** `lib/openrouter/openrouter.model.dart:10-22`

- [ ] **Step 1: Add imageDelta field to stream chunk**

```dart
class OpenRouterStreamChunk {
  final String? id;
  final int? created;
  final String? content;
  final String? finishReason;
  final AssistantImage? imageDelta;

  OpenRouterStreamChunk({
    this.id,
    this.created,
    this.content,
    this.finishReason,
    this.imageDelta,
  });
}
```

### 1.4: Add `ImageConfig` class

**File:** `lib/openrouter/openrouter.model.dart`

- [ ] **Step 1: Add after `AssistantImage`**

```dart
class ImageConfig {
  final String aspectRatio;
  final String imageSize;

  const ImageConfig({
    required this.aspectRatio,
    required this.imageSize,
  });

  Map<String, dynamic> toJson() => {
    'aspect_ratio': aspectRatio,
    'image_size': imageSize,
  };
}
```

### 1.5: Add `AssistantContentPart` for multi-part responses

**File:** `lib/openrouter/openrouter.model.dart`

- [ ] **Step 1: Add after `ImageConfig`**

```dart
class AssistantContentPart extends Equatable {
  final String? text;
  final AssistantImage? image;

  const AssistantContentPart._({
    this.text,
    this.image,
  });

  factory AssistantContentPart.text(String value) => AssistantContentPart._(text: value);
  factory AssistantContentPart.image(AssistantImage img) => AssistantContentPart._(image: img);

  @override
  List<Object?> get props => [text, image];
}
```

### 1.6: Extend `Message` with images field

**File:** `lib/chat/message.model.dart:13-71`

- [ ] **Step 1: Add images field and update copyWith**

Add after `toolCallsProcessed`:
```dart
final List<AssistantImage>? images;
```

Update `copyWith`:
```dart
Message copyWith({
  // ... existing params ...
  List<AssistantImage>? images,
}) {
  return Message(
    // ... existing args ...
    images: images ?? this.images,
  );
}
```

### 1.7: Update `Chat.toJson`/`fromJson` for images

**File:** `lib/chat/chat.model.dart:35-83`

- [ ] **Step 1: Add images to `toJson`**

In the message mapping inside `toJson`:
```dart
'images': m.images?.map((i) => i.toJson()).toList(),
```

- [ ] **Step 2: Parse images in `fromJson`**

```dart
images: m['images'] != null
    ? (m['images'] as List)
        .map((i) => AssistantImage.fromJson(i as Map<String, dynamic>))
        .toList()
    : null,
```

### 1.8: Update `ChatDatabaseService` serialization

**File:** `lib/database/chat_database.service.dart`

- [ ] **Step 1: Add images to message metadata in `_encodeChatMarkdown`** (line ~180)

In the JSON encoding for each message, add:
```dart
'images': message.images?.map((i) => i.toJson()).toList(),
```

- [ ] **Step 2: Parse images in `_readChat`** (line ~123-138)

```dart
images: metadata['images'] != null
    ? (metadata['images'] as List)
        .map((i) => AssistantImage.fromJson(Map<String, dynamic>.from(i as Map)))
        .toList()
    : null,
```

---

## Task 2: Phase 2 - Request Pipeline Wiring

### 2.1: Extend `OpenRouterService.send` for image params

**File:** `lib/openrouter/openrouter.service.dart:34-112`

- [ ] **Step 1: Add image params to `send` method signature**

```dart
Stream<OpenRouterStreamChunk> send({
  // ... existing params ...
  ImageModalities? modalities,
  ImageConfig? imageConfig,
})
```

- [ ] **Step 2: Add image fields to request body** (after `parallel_tool_calls`)

```dart
if (modalities != null) {
  body['modalities'] = modalities.modalities;
}
if (imageConfig != null) {
  body['image_config'] = imageConfig.toJson();
}
```

- [ ] **Step 3: Handle image content in stream parsing** (line ~93-106)

After parsing delta content:
```dart
// Check for image delta in delta.content (base64 data URLs)
if (delta != null && delta.isNotEmpty) {
  if (delta.startsWith('data:image')) {
    yield OpenRouterStreamChunk(
      id: responseId,
      created: createdTimestamp,
      imageDelta: AssistantImage(
        base64Data: delta,
        mimeType: 'image/png', // infer from data URL if possible
      ),
    );
  } else {
    yield OpenRouterStreamChunk(
      id: responseId,
      created: createdTimestamp,
      content: delta,
      finishReason: finishReason,
    );
  }
}
```

### 2.2: Extend `OpenRouterService.sendNonStreamingCompletion`

**File:** `lib/openrouter/openrouter.service.dart:141-184`

- [ ] **Step 1: Add image params and body fields** (same pattern as `send`)

### 2.3: Extend `openrouter.provider.dart` methods

**File:** `lib/openrouter/openrouter.provider.dart`

- [ ] **Step 1: Add image params to `send`, `sendNonStreaming`, `sendCompletionNonStreaming`**

```dart
Stream<OpenRouterStreamChunk> send({
  // ... existing params ...
  ImageModalities? modalities,
  ImageConfig? imageConfig,
})
```

### 2.4: Add image validation in `chat.provider.dart`

**File:** `lib/chat/chat.provider.dart`

- [ ] **Step 1: Add image output validation in `sendMessage`** (after line 104)

After the image input check:
```dart
final imageEnabled = ...; // need to pass this from UI
if (imageEnabled && selectedModel != null && !selectedModel.supportsImageOutput) {
  throw Exception(
    'The selected model does not support image output. Choose a model that can generate images.',
  );
}
```

### 2.5: Build image request in `_sendMessageStreaming`

**File:** `lib/chat/chat.provider.dart:233-259`

- [ ] **Step 1: Pass image params to openRouter.send**

```dart
final stream = openRouter.send(
  messages: initialMessages,
  modelId: modelId,
  modalities: imageModalities,  // new param
  imageConfig: imageConfig,      // new param
);
```

- [ ] **Step 2: Accumulate images alongside text**

```dart
String accumulatedResponse = '';
List<AssistantImage> accumulatedImages = [];
await for (final chunk in stream) {
  if (chunk.content != null) {
    accumulatedResponse += chunk.content!;
  }
  if (chunk.imageDelta != null) {
    accumulatedImages.add(chunk.imageDelta!);
  }
  state = state.copyWith(
    accumulatedResponse: Nullable(accumulatedResponse),
  );
}
```

- [ ] **Step 3: Create message with images**

```dart
final finalMessage = Message(
  // ... existing fields ...
  images: accumulatedImages.isNotEmpty ? accumulatedImages : null,
);
```

### 2.6: Handle image responses in `_sendMessageWithTools`

**File:** `lib/chat/chat.provider.dart:261-308`

- [ ] **Step 1: Parse image content from completion message**

When processing `choice.message`, check if content is a list (multi-part) or string:
```dart
// Handle multi-part content with images
final content = assistantMessage.content;
List<AssistantImage>? images;
// If content is a list, parse text and images
// Otherwise, just use content as text
```

---

## Task 3: Phase 3 - Composer UI Controls

### 3.1: Add image output state to `ChatState`

**File:** `lib/chat/chat.state.dart`

- [ ] **Step 1: Add image output state fields**

```dart
class ChatState extends Equatable {
  // ... existing fields ...
  final bool imageGenerationEnabled;
  final ImageModalities? imageModalities;
  final String? aspectRatio;
  final String? imageSize;

  const ChatState({
    // ... existing fields ...
    this.imageGenerationEnabled = false,
    this.imageModalities,
    this.aspectRatio,
    this.imageSize,
  });

  ChatState copyWith({
    // ... existing params ...
    bool? imageGenerationEnabled,
    ImageModalities? imageModalities,
    String? aspectRatio,
    String? imageSize,
  }) {
    return ChatState(
      // ... existing args ...
      imageGenerationEnabled: imageGenerationEnabled ?? this.imageGenerationEnabled,
      imageModalities: imageModalities ?? this.imageModalities,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      imageSize: imageSize ?? this.imageSize,
    );
  }
}
```

### 3.2: Add model capability resolution in `chat.page.dart`

**File:** `lib/chat/chat.page.dart`

- [ ] **Step 1: Get selected model and pass capability to composer**

After `selectedModelId` definition (line ~184):
```dart
final openRouterModelsState = ref.watch(openRouterModelsProvider);
final selectedModel = openRouterModelsState.models.firstWhereOrNull(
  (m) => m.id == selectedModelId,
);
final supportsImageOutput = selectedModel?.supportsImageOutput ?? false;
```

- [ ] **Step 2: Pass to ComposerWidget**

In the ComposerWidget call (line ~265):
```dart
ComposerWidget(
  // ... existing params ...
  supportsImageOutput: supportsImageOutput,
  imageGenerationEnabled: chatState.imageGenerationEnabled,
  imageModalities: chatState.imageModalities,
  aspectRatio: chatState.aspectRatio,
  imageSize: chatState.imageSize,
  onImageGenerationChanged: (enabled) {
    if (chatId == null) return;
    ref.read(chatProvider(chatId!).notifier).setImageGeneration(enabled);
  },
  onImageModalitiesChanged: (m) { /* ... */ },
  onAspectRatioChanged: (r) { /* ... */ },
  onImageSizeChanged: (s) { /* ... */ },
),
```

### 3.3: Add image output controls to `ComposerWidget`

**File:** `lib/chat/composer.widget.dart`

- [ ] **Step 1: Add new props**

```dart
class ComposerWidget extends StatelessWidget {
  // ... existing props ...
  final bool supportsImageOutput;
  final bool imageGenerationEnabled;
  final ImageModalities? imageModalities;
  final String? aspectRatio;
  final String? imageSize;
  final ValueChanged<bool>? onImageGenerationChanged;
  final ValueChanged<ImageModalities>? onImageModalitiesChanged;
  final ValueChanged<String>? onAspectRatioChanged;
  final ValueChanged<String>? onImageSizeChanged;
}
```

- [ ] **Step 2: Add conditional image controls group**

In the `Column` children, after the first `Row` (text input row), add:

```dart
if (supportsImageOutput) ...[
  const SizedBox(height: 8),
  _ImageOutputControls(
    enabled: imageGenerationEnabled,
    modalities: imageModalities,
    aspectRatio: aspectRatio,
    imageSize: imageSize,
    onEnabledChanged: onImageGenerationChanged,
    onModalitiesChanged: onImageModalitiesChanged,
    onAspectRatioChanged: onAspectRatioChanged,
    onImageSizeChanged: onImageSizeChanged,
  ),
],
```

### 3.4: Create `_ImageOutputControls` widget

**File:** `lib/chat/composer.widget.dart`

- [ ] **Step 1: Add `_ImageOutputControls` class**

```dart
class _ImageOutputControls extends StatelessWidget {
  const _ImageOutputControls({
    required this.enabled,
    this.modalities,
    this.aspectRatio,
    this.imageSize,
    this.onEnabledChanged,
    this.onModalitiesChanged,
    this.onAspectRatioChanged,
    this.onImageSizeChanged,
  });

  final bool enabled;
  final ImageModalities? modalities;
  final String? aspectRatio;
  final String? imageSize;
  final ValueChanged<bool>? onEnabledChanged;
  final ValueChanged<ImageModalities>? onModalitiesChanged;
  final ValueChanged<String>? onAspectRatioChanged;
  final ValueChanged<String>? onImageSizeChanged;

  static const _aspectRatios = ['1:1', '16:9', '4:3', '3:2', '9:16'];
  static const _imageSizes = ['1024x1024', '1536x1536', '1024x1792', '1792x1024'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      spacing: 8,
      children: [
        Switch(
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        Text('Image', style: theme.textTheme.bodySmall),
        if (enabled) ...[
          _Dropdown<ImageModalities>(
            value: modalities ?? ImageModalities.imagePlusText,
            items: ImageModalities.values,
            labelBuilder: (m) => switch (m) {
              ImageModalities.textOnly => 'Text only',
              ImageModalities.imageOnly => 'Image only',
              ImageModalities.imagePlusText => 'Image + Text',
            },
            onChanged: onModalitiesChanged,
          ),
          _Dropdown<String>(
            value: aspectRatio ?? '1:1',
            items: _aspectRatios,
            labelBuilder: (r) => r,
            onChanged: onAspectRatioChanged,
          ),
          _Dropdown<String>(
            value: imageSize ?? '1024x1024',
            items: _imageSizes,
            labelBuilder: (s) => s,
            onChanged: onImageSizeChanged,
          ),
        ],
      ],
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.labelBuilder,
    this.onChanged,
  });

  final T value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<T>(
      value: value,
      items: items.map((item) => DropdownMenuItem(
        value: item,
        child: Text(labelBuilder(item)),
      )).toList(),
      onChanged: onChanged != null ? (v) => onChanged!(v!) : null,
      isDense: true,
    );
  }
}
```

### 3.5: Add `setImageGeneration` method to `ChatNotifier`

**File:** `lib/chat/chat.provider.dart`

- [ ] **Step 1: Add method after `selectModel`**

```dart
void setImageGeneration(bool enabled) {
  state = state.copyWith(
    imageGenerationEnabled: enabled,
    imageModalities: enabled ? ImageModalities.imagePlusText : null,
    aspectRatio: enabled ? '1:1' : null,
    imageSize: enabled ? '1024x1024' : null,
  );
}
```

- [ ] **Step 2: Add setters for individual fields**

```dart
void setImageModalities(ImageModalities modalities) {
  state = state.copyWith(imageModalities: modalities);
}

void setAspectRatio(String ratio) {
  state = state.copyWith(aspectRatio: ratio);
}

void setImageSize(String size) {
  state = state.copyWith(imageSize: size);
}
```

---

## Task 4: Phase 4 - Model Discovery Enhancement

### 4.1: Add image-capable filter to `_ModelPickerDialog`

**File:** `lib/chat/select_ai_model.dialog.dart:144-201`

- [ ] **Step 1: Add filter state**

```dart
class _ModelPickerDialogState extends State<_ModelPickerDialog> {
  // ... existing state ...
  bool _showImageCapableOnly = false;
```

- [ ] **Step 2: Filter models in `_filteredModels`**

Add filter condition:
```dart
List<OpenRouterModel> get _filteredModels {
  final query = _searchController.text.toLowerCase();
  final filtered = widget.models
      .where((model) {
        final matchesQuery = model.name.toLowerCase().contains(query);
        final matchesImageFilter = !_showImageCapableOnly || model.supportsImageOutput;
        return matchesQuery && matchesImageFilter;
      })
      .toList();
  // ... rest unchanged ...
}
```

### 4.2: Add filter toggle UI

**File:** `lib/chat/select_ai_model.dialog.dart:237-245`

- [ ] **Step 1: Add filter button in the wrap**

In the `Wrap` children:
```dart
FilterChip(
  label: Text('Image-capable${_showImageCapableOnly ? ' (${_filteredModels.length})' : ''}'),
  selected: _showImageCapableOnly,
  onSelected: (selected) {
    setState(() {
      _showImageCapableOnly = selected;
    });
  },
),
```

---

## Task 5: Phase 5 - Chat Rendering

### 5.1: Add image rendering to `MessageWidget`

**File:** `lib/chat/message.widget.dart`

- [ ] **Step 1: Add `dart:convert` import** (already present for base64)

- [ ] **Step 2: Extract image rendering method**

```dart
Widget _buildAssistantImages(List<AssistantImage> images) {
  return Wrap(
    spacing: 8,
    runSpacing: 8,
    children: images.map((img) {
      return ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 400,
        ),
        child: Image.memory(
          base64Decode(img.base64Data.split(',').last),
          fit: BoxFit.contain,
        ),
      );
    }).toList(),
  );
}
```

- [ ] **Step 3: Insert image rendering in build method**

After the `MarkdownBody` (line ~113), before the tool call buttons (line ~129):

```dart
if (role == MessageRole.assistant && widget.message.images != null && widget.message.images!.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 8),
    child: _buildAssistantImages(widget.message.images!),
  ),
```

---

## Task 6: Verification

### 6.1: Run static analysis

```bash
cd /Users/matteo/prototypes/contextch.at/app
flutter analyze
```

Expected: No new errors in touched files.

### 6.2: Manual verification steps

- [ ] Select text-only model → image controls hidden in composer
- [ ] Select image-output model → image controls visible
- [ ] Enable image generation, send → payload contains `modalities` and `image_config`
- [ ] Disable image generation → text flow unchanged
- [ ] Generate image → assistant images render in chat
- [ ] Text+image response → both text and images display
- [ ] Reload app → generated images persist
- [ ] Toggle image-capable filter → only image-capable models shown, custom model entry still works
