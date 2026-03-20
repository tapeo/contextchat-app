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
  final String? finishReason;

  OpenRouterStreamChunk({
    this.id,
    this.created,
    this.content,
    this.finishReason,
  });
}

class OpenRouterToolFunction extends Equatable {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;

  const OpenRouterToolFunction({
    required this.name,
    required this.description,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'parameters': parameters,
  };

  @override
  List<Object?> get props => [name, description, parameters];
}

class OpenRouterToolDefinition extends Equatable {
  final String type;
  final OpenRouterToolFunction function;

  const OpenRouterToolDefinition({
    this.type = 'function',
    required this.function,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'function': function.toJson(),
  };

  @override
  List<Object?> get props => [type, function];
}

class OpenRouterToolChoice extends Equatable {
  final String? mode;
  final String? functionName;

  const OpenRouterToolChoice._({this.mode, this.functionName});

  const OpenRouterToolChoice.auto() : this._(mode: 'auto');
  const OpenRouterToolChoice.none() : this._(mode: 'none');
  const OpenRouterToolChoice.function(String name) : this._(functionName: name);

  Object toJson() {
    if (functionName != null) {
      return {
        'type': 'function',
        'function': {'name': functionName},
      };
    }
    return mode ?? 'auto';
  }

  @override
  List<Object?> get props => [mode, functionName];
}

class OpenRouterToolCallFunction extends Equatable {
  final String name;
  final String arguments;

  const OpenRouterToolCallFunction({
    required this.name,
    required this.arguments,
  });

  factory OpenRouterToolCallFunction.fromJson(Map<String, dynamic> json) {
    return OpenRouterToolCallFunction(
      name: json['name'] as String,
      arguments: (json['arguments'] as String?) ?? '{}',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'arguments': arguments};

  @override
  List<Object?> get props => [name, arguments];
}

class OpenRouterToolCall extends Equatable {
  final String id;
  final String type;
  final OpenRouterToolCallFunction function;

  const OpenRouterToolCall({
    required this.id,
    this.type = 'function',
    required this.function,
  });

  factory OpenRouterToolCall.fromJson(Map<String, dynamic> json) {
    return OpenRouterToolCall(
      id: json['id'] as String,
      type: (json['type'] as String?) ?? 'function',
      function: OpenRouterToolCallFunction.fromJson(
        Map<String, dynamic>.from(json['function'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'function': function.toJson(),
  };

  @override
  List<Object?> get props => [id, type, function];
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
  final List<OpenRouterToolCall>? toolCalls;
  final String? toolCallId;
  final String? name;

  const OpenRouterMessage({
    required this.role,
    this.content,
    this.toolCalls,
    this.toolCallId,
    this.name,
  }) : contentParts = null;

  const OpenRouterMessage.multipart({
    required this.role,
    required List<OpenRouterMessageContentPart> this.contentParts,
    this.toolCalls,
    this.toolCallId,
    this.name,
  }) : content = null;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'role': role,
      'content': contentParts != null
          ? contentParts!.map((part) => part.toJson()).toList()
          : content,
    };

    if (toolCalls != null && toolCalls!.isNotEmpty) {
      payload['tool_calls'] = toolCalls!.map((call) => call.toJson()).toList();
    }
    if (toolCallId != null) {
      payload['tool_call_id'] = toolCallId;
    }
    if (name != null) {
      payload['name'] = name;
    }

    return payload;
  }

  @override
  List<Object?> get props => [
    role,
    content,
    contentParts,
    toolCalls,
    toolCallId,
    name,
  ];
}

class OpenRouterCompletionMessage extends Equatable {
  final String role;
  final String? content;
  final List<OpenRouterToolCall>? toolCalls;

  const OpenRouterCompletionMessage({
    required this.role,
    required this.content,
    this.toolCalls,
  });

  factory OpenRouterCompletionMessage.fromJson(Map<String, dynamic> json) {
    final rawToolCalls = json['tool_calls'] as List<dynamic>?;
    return OpenRouterCompletionMessage(
      role: (json['role'] as String?) ?? 'assistant',
      content: json['content'] as String?,
      toolCalls: rawToolCalls
          ?.map(
            (item) => OpenRouterToolCall.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [role, content, toolCalls];
}

class OpenRouterCompletionChoice extends Equatable {
  final int index;
  final String? finishReason;
  final OpenRouterCompletionMessage message;

  const OpenRouterCompletionChoice({
    required this.index,
    required this.finishReason,
    required this.message,
  });

  factory OpenRouterCompletionChoice.fromJson(Map<String, dynamic> json) {
    return OpenRouterCompletionChoice(
      index: (json['index'] as int?) ?? 0,
      finishReason: json['finish_reason'] as String?,
      message: OpenRouterCompletionMessage.fromJson(
        Map<String, dynamic>.from(json['message'] as Map),
      ),
    );
  }

  @override
  List<Object?> get props => [index, finishReason, message];
}

class OpenRouterChatCompletion extends Equatable {
  final String? id;
  final int? created;
  final List<OpenRouterCompletionChoice> choices;

  const OpenRouterChatCompletion({
    required this.id,
    required this.created,
    required this.choices,
  });

  factory OpenRouterChatCompletion.fromJson(Map<String, dynamic> json) {
    return OpenRouterChatCompletion(
      id: json['id'] as String?,
      created: json['created'] as int?,
      choices: (json['choices'] as List<dynamic>? ?? const [])
          .map(
            (item) => OpenRouterCompletionChoice.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, created, choices];
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
