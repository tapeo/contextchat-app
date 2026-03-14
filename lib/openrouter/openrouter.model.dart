import 'package:equatable/equatable.dart';

class OpenRouterResponse {
  final String response;
  final int tokens;

  OpenRouterResponse({required this.response, required this.tokens});
}

class OpenRouterStreamChunk {
  final String? id;
  final int? created;
  final String? content;

  OpenRouterStreamChunk({this.id, this.created, this.content});
}

class OpenRouterMessageContentPart extends Equatable {
  final String type;
  final String? text;
  final String? imageUrl;

  const OpenRouterMessageContentPart._({
    required this.type,
    this.text,
    this.imageUrl,
  });

  const OpenRouterMessageContentPart.text(String value)
    : this._(type: 'text', text: value);

  const OpenRouterMessageContentPart.imageUrl(String url)
    : this._(type: 'image_url', imageUrl: url);

  Map<String, dynamic> toJson() {
    switch (type) {
      case 'text':
        return {'type': type, 'text': text};
      case 'image_url':
        return {
          'type': type,
          'image_url': {'url': imageUrl},
        };
      default:
        throw UnsupportedError('Unsupported content part type: $type');
    }
  }

  @override
  List<Object?> get props => [type, text, imageUrl];
}

class OpenRouterMessage extends Equatable {
  final String role;
  final String? content;
  final List<OpenRouterMessageContentPart>? contentParts;

  const OpenRouterMessage({required this.role, required String this.content})
    : contentParts = null;

  const OpenRouterMessage.multipart({
    required this.role,
    required List<OpenRouterMessageContentPart> this.contentParts,
  }) : content = null;

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': contentParts != null
          ? contentParts!.map((part) => part.toJson()).toList()
          : content,
    };
  }

  @override
  List<Object?> get props => [role, content, contentParts];
}

class Architecture {
  final String modality;
  final List<String> inputModalities;
  final List<String> outputModalities;
  final String tokenizer;
  final String? instructType;

  Architecture({
    required this.modality,
    required this.inputModalities,
    required this.outputModalities,
    required this.tokenizer,
    this.instructType,
  });

  factory Architecture.fromJson(Map<String, dynamic> json) {
    return Architecture(
      modality: json['modality'],
      inputModalities: List<String>.from(json['input_modalities']),
      outputModalities: List<String>.from(json['output_modalities']),
      tokenizer: json['tokenizer'],
      instructType: json['instruct_type'],
    );
  }
}

class Pricing {
  final String? prompt;
  final String? completion;
  final String? request;
  final String? image;
  final String? webSearch;
  final String? internalReasoning;
  final String? inputCacheRead;
  final String? inputCacheWrite;

  Pricing({
    required this.prompt,
    required this.completion,
    required this.request,
    required this.image,
    required this.webSearch,
    required this.internalReasoning,
    this.inputCacheRead,
    this.inputCacheWrite,
  });

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      prompt: json['prompt'],
      completion: json['completion'],
      request: json['request'],
      image: json['image'],
      webSearch: json['web_search'],
      internalReasoning: json['internal_reasoning'],
      inputCacheRead: json['input_cache_read'],
      inputCacheWrite: json['input_cache_write'],
    );
  }
}

class TopProvider {
  final int? contextLength;
  final int? maxCompletionTokens;
  final bool isModerated;

  TopProvider({
    this.contextLength,
    this.maxCompletionTokens,
    required this.isModerated,
  });

  factory TopProvider.fromJson(Map<String, dynamic> json) {
    return TopProvider(
      contextLength: json['context_length'],
      maxCompletionTokens: json['max_completion_tokens'],
      isModerated: json['is_moderated'],
    );
  }
}

class OpenRouterModel {
  final String id;
  final String canonicalSlug;
  final String? huggingFaceId;
  final String name;
  final int created;
  final String description;
  final int contextLength;
  final Architecture architecture;
  final Pricing pricing;
  final TopProvider topProvider;
  final dynamic perRequestLimits;
  final List<String> supportedParameters;
  final Map<String, dynamic>? defaultParameters;

  OpenRouterModel({
    required this.id,
    required this.canonicalSlug,
    this.huggingFaceId,
    required this.name,
    required this.created,
    required this.description,
    required this.contextLength,
    required this.architecture,
    required this.pricing,
    required this.topProvider,
    this.perRequestLimits,
    required this.supportedParameters,
    required this.defaultParameters,
  });

  factory OpenRouterModel.fromJson(Map<String, dynamic> json) {
    return OpenRouterModel(
      id: json['id'],
      canonicalSlug: json['canonical_slug'],
      huggingFaceId: json['hugging_face_id'],
      name: json['name'],
      created: json['created'],
      description: json['description'],
      contextLength: json['context_length'],
      architecture: Architecture.fromJson(json['architecture']),
      pricing: Pricing.fromJson(json['pricing']),
      topProvider: TopProvider.fromJson(json['top_provider']),
      perRequestLimits: json['per_request_limits'],
      supportedParameters: List<String>.from(json['supported_parameters']),
      defaultParameters: json['default_parameters'] as Map<String, dynamic>?,
    );
  }

  bool get supportsImageInput => architecture.inputModalities.any(
    (modality) => modality.toLowerCase() == 'image',
  );
}
