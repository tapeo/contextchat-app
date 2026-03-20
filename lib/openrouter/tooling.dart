import 'dart:convert';

import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/projects/project_file_types.dart';
import 'package:contextchat/projects/projects.model.dart';

class OpenRouterToolSpec {
  final OpenRouterToolDefinition definition;
  final bool sensitive;

  const OpenRouterToolSpec({required this.definition, this.sensitive = false});
}

class OpenRouterToolExecutionResult {
  final String content;
  final bool isError;

  const OpenRouterToolExecutionResult({
    required this.content,
    this.isError = false,
  });
}

typedef OpenRouterToolExecutor =
    Future<OpenRouterToolExecutionResult> Function(Map<String, dynamic> args);

class OpenRouterRegisteredTool {
  final OpenRouterToolSpec spec;
  final OpenRouterToolExecutor execute;

  const OpenRouterRegisteredTool({required this.spec, required this.execute});
}

class OpenRouterToolRegistry {
  OpenRouterToolRegistry({required List<OpenRouterRegisteredTool> tools})
    : _tools = {
        for (final tool in tools) tool.spec.definition.function.name: tool,
      };

  final Map<String, OpenRouterRegisteredTool> _tools;

  List<OpenRouterToolDefinition> get definitions => _tools.values
      .map((entry) => entry.spec.definition)
      .toList(growable: false);

  OpenRouterRegisteredTool? operator [](String name) => _tools[name];
}

OpenRouterToolRegistry buildGlobalToolRegistry({
  required Project? project,
  required ProjectDatabaseService projectsDatabase,
}) {
  return OpenRouterToolRegistry(
    tools: [
      OpenRouterRegisteredTool(
        spec: OpenRouterToolSpec(
          definition: OpenRouterToolDefinition(
            function: OpenRouterToolFunction(
              name: 'get_current_datetime',
              description:
                  'Returns the current local datetime and UTC datetime in ISO-8601 format.',
              parameters: const {
                'type': 'object',
                'properties': {},
                'required': [],
              },
            ),
          ),
          sensitive: false,
        ),
        execute: (_) async {
          final now = DateTime.now();
          return OpenRouterToolExecutionResult(
            content: jsonEncode({
              'local': now.toIso8601String(),
              'utc': now.toUtc().toIso8601String(),
            }),
          );
        },
      ),
      OpenRouterRegisteredTool(
        spec: OpenRouterToolSpec(
          definition: OpenRouterToolDefinition(
            function: OpenRouterToolFunction(
              name: 'list_project_files',
              description:
                  'Lists files available in the currently selected project context.',
              parameters: const {
                'type': 'object',
                'properties': {},
                'required': [],
              },
            ),
          ),
          sensitive: false,
        ),
        execute: (_) async {
          if (project == null) {
            return const OpenRouterToolExecutionResult(content: '[]');
          }

          final payload = project.files
              .map(
                (file) => {
                  'id': file.id,
                  'name': file.name,
                  'filename': file.filename,
                  'sizeBytes': file.sizeBytes,
                },
              )
              .toList(growable: false);
          return OpenRouterToolExecutionResult(content: jsonEncode(payload));
        },
      ),
      OpenRouterRegisteredTool(
        spec: OpenRouterToolSpec(
          definition: OpenRouterToolDefinition(
            function: OpenRouterToolFunction(
              name: 'read_project_file',
              description:
                  'Reads a text file from the currently selected project by filename or display name.',
              parameters: const {
                'type': 'object',
                'properties': {
                  'file_name': {
                    'type': 'string',
                    'description': 'Project file name or file system filename.',
                  },
                },
                'required': ['file_name'],
              },
            ),
          ),
          sensitive: true,
        ),
        execute: (args) async {
          if (project == null) {
            return const OpenRouterToolExecutionResult(
              content: '{"error":"No active project selected"}',
              isError: true,
            );
          }

          final fileName = (args['file_name'] as String?)?.trim();
          if (fileName == null || fileName.isEmpty) {
            return const OpenRouterToolExecutionResult(
              content: '{"error":"Missing required argument: file_name"}',
              isError: true,
            );
          }

          final matched = project.files
              .where((file) {
                return file.name.toLowerCase() == fileName.toLowerCase() ||
                    file.filename.toLowerCase() == fileName.toLowerCase();
              })
              .toList(growable: false);

          if (matched.isEmpty) {
            return OpenRouterToolExecutionResult(
              content: jsonEncode({'error': 'File not found: $fileName'}),
              isError: true,
            );
          }

          final file = matched.first;
          final mimeType = imageMimeTypeForFileName(file.filename);
          if (mimeType != null) {
            return OpenRouterToolExecutionResult(
              content: jsonEncode({
                'error': 'File is binary/image and cannot be read as text',
                'filename': file.filename,
              }),
              isError: true,
            );
          }

          final contents = await projectsDatabase.readProjectFileContents(
            project.id,
            file,
          );
          if (contents == null) {
            return OpenRouterToolExecutionResult(
              content: jsonEncode({'error': 'Unable to read file contents'}),
              isError: true,
            );
          }

          return OpenRouterToolExecutionResult(
            content: jsonEncode({
              'filename': file.filename,
              'name': file.name,
              'content': contents,
            }),
          );
        },
      ),
    ],
  );
}
