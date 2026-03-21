import 'package:contextchat/message/message.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:equatable/equatable.dart';

class Chat extends Equatable {
  final String id;
  final String? projectId;
  final String? title;
  final List<Message> messages;
  final DateTime? updatedAt;
  final bool toolsEnabled;
  final bool imageOutputEnabled;
  final ImageModalities imageModalities;
  final ImageAspectRatio imageAspectRatio;
  final ImageSize imageSize;

  const Chat({
    required this.id,
    this.projectId,
    this.title,
    required this.messages,
    this.updatedAt,
    this.toolsEnabled = true,
    this.imageOutputEnabled = false,
    this.imageModalities = ImageModalities.imagePlusText,
    this.imageAspectRatio = ImageAspectRatio.ratio1x1,
    this.imageSize = ImageSize.size1K,
  });

  Chat copyWith({
    String? id,
    String? projectId,
    String? title,
    List<Message>? messages,
    DateTime? updatedAt,
    bool? toolsEnabled,
    bool? imageOutputEnabled,
    ImageModalities? imageModalities,
    ImageAspectRatio? imageAspectRatio,
    ImageSize? imageSize,
  }) {
    return Chat(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      updatedAt: updatedAt ?? this.updatedAt,
      toolsEnabled: toolsEnabled ?? this.toolsEnabled,
      imageOutputEnabled: imageOutputEnabled ?? this.imageOutputEnabled,
      imageModalities: imageModalities ?? this.imageModalities,
      imageAspectRatio: imageAspectRatio ?? this.imageAspectRatio,
      imageSize: imageSize ?? this.imageSize,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'messages': messages
          .map(
            (message) => {
              'id': message.id,
              'timestamp': message.timestamp,
              'content': message.content,
              'role': message.role.name,
              'toolCallId': message.toolCallId,
              'toolName': message.toolName,
              'toolCallsJson': message.toolCallsJson,
              'toolError': message.toolError,
              'toolCallsProcessed': message.toolCallsProcessed,
              'images': message.images?.map((image) => image.toJson()).toList(),
            },
          )
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
      'toolsEnabled': toolsEnabled,
      'imageOutputEnabled': imageOutputEnabled,
      'imageModalities': imageModalities.name,
      'imageAspectRatio': imageAspectRatio,
      'imageSize': imageSize,
    };
  }

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] as String,
      projectId: json['projectId'] as String?,
      title: json['title'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map(
            (message) => Message(
              id: message['id'] as String,
              timestamp: message['timestamp'] as String,
              content: message['content'] as String,
              role: MessageRole.values.firstWhere(
                (r) => r.name == message['role'],
              ),
              toolCallId: message['toolCallId'] as String?,
              toolName: message['toolName'] as String?,
              toolCallsJson: message['toolCallsJson'] as String?,
              toolError: (message['toolError'] as bool?) ?? false,
              toolCallsProcessed:
                  (message['toolCallsProcessed'] as bool?) ?? false,
              images: message['images'] != null
                  ? (message['images'] as List)
                        .map(
                          (image) => AssistantImage.fromJson(
                            image as Map<String, dynamic>,
                          ),
                        )
                        .toList()
                  : null,
              model: message['model'] as String?,
            ),
          )
          .toList(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      toolsEnabled: (json['toolsEnabled'] as bool?) ?? true,
      imageOutputEnabled: (json['imageOutputEnabled'] as bool?) ?? false,
      imageModalities: json['imageModalities'] != null
          ? ImageModalities.values.firstWhere(
              (m) => m.name == json['imageModalities'],
              orElse: () => ImageModalities.imagePlusText,
            )
          : ImageModalities.imagePlusText,
      imageAspectRatio: _parseImageAspectRatio(
        json['imageAspectRatio'] as String?,
      ),
      imageSize: _parseImageSize(json['imageSize'] as String?),
    );
  }

  @override
  List<Object?> get props => [
    id,
    projectId,
    title,
    messages,
    updatedAt,
    toolsEnabled,
    imageOutputEnabled,
    imageModalities,
    imageAspectRatio,
    imageSize,
  ];

  static ImageAspectRatio _parseImageAspectRatio(String? value) {
    if (value == null) return ImageAspectRatio.ratio1x1;
    return ImageAspectRatio.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ImageAspectRatio.ratio1x1,
    );
  }

  static ImageSize _parseImageSize(String? value) {
    if (value == null) return ImageSize.size1K;
    return ImageSize.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ImageSize.size1K,
    );
  }
}
