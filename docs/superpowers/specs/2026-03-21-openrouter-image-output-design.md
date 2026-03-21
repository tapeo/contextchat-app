# OpenRouter Image Output Support - Design Spec

## Overview

Add end-to-end image generation support via OpenRouter's API. When a selected model advertises image output capability, users can enable image generation in the composer, configure basic parameters (modalities, aspect ratio, image size), and receive rendered images in chat.

## Capability Detection

### OpenRouterModel Extension (`openrouter.model.dart`)

Add a capability getter:

```dart
bool get supportsImageOutput => architecture.outputModalities.any(
  (modality) => modality.toLowerCase() == 'image',
);
```

## Request Structures

### Modalities Enum

```dart
enum ImageModalities {
  textOnly,
  imageOnly,
  imagePlusText,
}
```

### ImageConfig

```dart
class ImageConfig {
  final String aspectRatio; // e.g., "1:1", "16:9", "4:3", "3:2", "9:16"
  final String imageSize;   // e.g., "1024x1024", "1536x1536", "1024x1792"
}
```

### Request Fields

When image generation is enabled, include in the API request:

```json
{
  "modalities": ["image", "text"],
  "image_config": {
    "aspect_ratio": "16:9",
    "image_size": "1024x1024"
  }
}
```

- `textOnly`: `modalities: ["text"]` (or omit image_config entirely)
- `imageOnly`: `modalities: ["image"]`
- `imagePlusText`: `modalities: ["image", "text"]`

## Response Parsing

OpenRouter returns multi-part content for image responses. Handle both streaming and non-streaming:

```dart
class AssistantContentPart {
  final String? text;
  final String? base64ImageData; // data:image/png;base64,...
  final String? mimeType;
}
```

Stream delta handling must accumulate image parts alongside text deltas.

## Message Domain Model (`message.model.dart`)

Add optional images field to Message:

```dart
class Message {
  // ... existing fields ...
  final List<AssistantImage>? images;
}

class AssistantImage {
  final String base64Data;
  final String mimeType;
  final int? width;
  final int? height;
}
```

### Serialization

Images serialized as base64 data URLs stored in message content OR in a dedicated `images` JSON field for cleaner storage:

```json
{
  "id": "msg_xxx",
  "role": "assistant",
  "images": [
    {"data": "data:image/png;base64,...", "mimeType": "image/png"}
  ]
}
```

## Storage (`chat_database.service.dart`)

- Messages with images stored via existing markdown+JSON format
- Images in `images` JSON array within message metadata
- Deserialization hydrates `message.images` field

## Composer UI (`composer.widget.dart`)

### Conditional Display

Image output controls shown **only** when:
1. A model is selected
2. `selectedModel.supportsImageOutput == true`
3. Model metadata has fully loaded

### Controls

**1. Enable Toggle**
- Switch/checkbox to enable/disable image generation
- When disabled, composer behaves normally

**2. Modalities Dropdown**
- Options: "Text only", "Image only", "Image + Text"
- Default: "Image + Text" when enabled

**3. Aspect Ratio Dropdown**
- Options: "1:1", "16:9", "4:3", "3:2", "9:16"
- Default: "1:1"

**4. Image Size Dropdown**
- Options: "1024x1024", "1536x1536", "1024x1792", "1792x1024"
- Default: "1024x1024"

### State Reset

When selected model changes:
- If new model lacks image output support: disable image generation, hide controls
- If settings are incompatible with new model capabilities: reset to defaults

### Loading State

Controls disabled while model metadata is loading (show them but greyed out).

## Model Picker Enhancement (`select_ai_model.dialog.dart`)

### Filter Toggle

Add a toggle/checkbox: "Show image-capable models only"

- **Default**: Off (show all models)
- **When enabled**: Filter list to models where `supportsImageOutput == true`
- Filter badge/count shown: "Image-capable (12)" etc.

### Custom Model Entry

- Custom model input remains visible and functional when filter is enabled
- User can still enter any model ID directly

## Chat Provider Changes (`chat.provider.dart`)

### Request Building

When `imageGenerationEnabled` and model supports it:
- Add `modalities` field to request based on selection
- Add `image_config` with `aspect_ratio` and `image_size`

### Response Handling

- Detect image content parts in streaming responses
- Accumulate image data alongside text
- Final message creation handles: text-only, image-only, text+image outputs

## Message Rendering (`message.widget.dart`)

### Image Display

- Parse `message.images` list
- Render each image with:
  - Max dimension: 400-600px
  - Responsive width
  - Tap to view full size (optional)
- Place images below text content, above tool calls

### Layout

```
[Markdown text content]

[Image 1] [Image 2]   (horizontal arrangement if space permits)
or
[Image - full width]

[Tool calls / actions]
```

### Text Copy

- Copy action copies text content only (images not included)
- Existing markdown copy behavior preserved

## Error Handling

- If API returns image in unsupported format: log warning, show text only
- If image generation fails: show error in message like tool errors
- Network errors during image fetch: show placeholder with retry

## Phase Boundaries

### Phase 1: Capability & Model/Data Foundation
- `supportsImageOutput` getter in `openrouter.model.dart`
- Request/response structures for image generation
- Message domain extension with `images` field
- Serialization in `message.model.dart`, `chat.model.dart`, `chat_database.service.dart`

### Phase 2: Request Pipeline Wiring
- OpenRouter service/provider request extension
- Chat provider image parameter validation and flow
- Composer → provider → service parameter passing

### Phase 3: Composer UI Controls
- Conditional rendering in `chat.page.dart` and `composer.widget.dart`
- All four controls (enable, modalities, aspect ratio, size)
- State reset on model change, disabled while loading

### Phase 4: Model Discovery Enhancement
- Filter toggle in `select_ai_model.dialog.dart`
- Custom model entry preserved

### Phase 5: Chat Rendering
- Image rendering in `message.widget.dart`
- Preserve markdown and tool-call rendering

## Out of Scope (This Phase)

- Sourceful-only advanced params (font_inputs, super_resolution_references)
- Image input/vision (already exists via project context)
- Image editing or variation
- Multiple images per response beyond API limits
