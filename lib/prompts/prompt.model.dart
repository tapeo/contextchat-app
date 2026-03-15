import 'package:equatable/equatable.dart';

class Prompt extends Equatable {
  final String id;
  final String name;
  final String description;
  final String promptText;
  final List<String> variables;
  final bool pinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Prompt({
    required this.id,
    required this.name,
    this.description = '',
    required this.promptText,
    this.variables = const [],
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Prompt copyWith({
    String? id,
    String? name,
    String? description,
    String? promptText,
    List<String>? variables,
    bool? pinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Prompt(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      promptText: promptText ?? this.promptText,
      variables: variables ?? this.variables,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'promptText': promptText,
      'variables': variables,
      'pinned': pinned,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory Prompt.fromJson(Map<String, dynamic> json) {
    final variables = <String>[];
    if (json['variables'] is List) {
      for (final entry in json['variables'] as List<dynamic>) {
        if (entry is String && entry.trim().isNotEmpty) {
          variables.add(entry.trim());
        }
      }
    }

    DateTime parseDate(Object? value) {
      if (value is String) {
        return DateTime.tryParse(value)?.toUtc() ?? DateTime.now().toUtc();
      }
      return DateTime.now().toUtc();
    }

    final createdAt = parseDate(json['createdAt']);
    final updatedAt = parseDate(json['updatedAt']);

    return Prompt(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Untitled Prompt',
      description: (json['description'] as String?) ?? '',
      promptText: (json['promptText'] as String?) ?? '',
      variables: variables,
      pinned: (json['pinned'] as bool?) ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    promptText,
    variables,
    pinned,
    createdAt,
    updatedAt,
  ];
}

