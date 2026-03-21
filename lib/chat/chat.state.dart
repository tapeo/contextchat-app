import 'package:contextchat/chat/chat.model.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:equatable/equatable.dart';

class ChatState extends Equatable {
  final Chat chat;
  final bool loading;
  final String? accumulatedResponse;
  final String? selectedModelId;
  final bool imageOutputEnabled;
  final ImageModalities imageModalities;
  final ImageAspectRatio imageAspectRatio;
  final ImageSize imageSize;
  final bool toolsEnabled;

  const ChatState({
    required this.chat,
    required this.loading,
    this.accumulatedResponse,
    this.selectedModelId,
    this.imageOutputEnabled = false,
    this.imageModalities = ImageModalities.imagePlusText,
    this.imageAspectRatio = ImageAspectRatio.ratio1x1,
    this.imageSize = ImageSize.size1K,
    this.toolsEnabled = true,
  });

  ChatState copyWith({
    Chat? chat,
    bool? loading,
    Nullable<String?>? accumulatedResponse,
    String? selectedModelId,
    bool? imageOutputEnabled,
    ImageModalities? imageModalities,
    ImageAspectRatio? imageAspectRatio,
    ImageSize? imageSize,
    bool? toolsEnabled,
  }) {
    return ChatState(
      chat: chat ?? this.chat,
      loading: loading ?? this.loading,
      accumulatedResponse: accumulatedResponse != null
          ? accumulatedResponse.value
          : this.accumulatedResponse,
      selectedModelId: selectedModelId ?? this.selectedModelId,
      imageOutputEnabled: imageOutputEnabled ?? this.imageOutputEnabled,
      imageModalities: imageModalities ?? this.imageModalities,
      imageAspectRatio: imageAspectRatio ?? this.imageAspectRatio,
      imageSize: imageSize ?? this.imageSize,
      toolsEnabled: toolsEnabled ?? this.toolsEnabled,
    );
  }

  @override
  List<Object?> get props => [
    chat,
    loading,
    accumulatedResponse,
    selectedModelId,
    imageOutputEnabled,
    imageModalities,
    imageAspectRatio,
    imageSize,
    toolsEnabled,
  ];
}

class Nullable<T> {
  final T? value;

  const Nullable(this.value);
}
