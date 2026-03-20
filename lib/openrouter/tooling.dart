import 'dart:convert';

import 'package:contextchat/database/project_database.service.dart';
import 'package:contextchat/openrouter/openrouter.model.dart';
import 'package:contextchat/projects/project_file_types.dart';
import 'package:contextchat/projects/projects.model.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

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
      OpenRouterRegisteredTool(
        spec: OpenRouterToolSpec(
          definition: OpenRouterToolDefinition(
            function: OpenRouterToolFunction(
              name: 'search_web',
              description:
                  'Searches the web using DuckDuckGo and returns a list of search results with titles, URLs, and snippets.',
              parameters: const {
                'type': 'object',
                'properties': {
                  'query': {
                    'type': 'string',
                    'description': 'The search query string.',
                  },
                },
                'required': ['query'],
              },
            ),
          ),
          sensitive: false,
        ),
        execute: (args) async {
          final query = (args['query'] as String?)?.trim();

          if (query == null || query.isEmpty) {
            return const OpenRouterToolExecutionResult(
              content: '{"error":"Missing required argument: query"}',
              isError: true,
            );
          }

          try {
            final searchUrl = Uri.parse(
              'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}',
            );

            final response = await http.get(searchUrl);

            if (response.statusCode != 200) {
              return OpenRouterToolExecutionResult(
                content: jsonEncode({
                  'error':
                      'Search failed with status code: ${response.statusCode}',
                }),
                isError: true,
              );
            }

            final document = parse(response.body);
            final results = <Map<String, String>>[];

            for (final result in document.querySelectorAll('.result')) {
              final titleElement = result.querySelector('.result__title a');
              final snippetElement = result.querySelector('.result__snippet');
              if (titleElement != null) {
                results.add({
                  'title': titleElement.text.trim(),
                  'url': titleElement.attributes['href'] ?? '',
                  'snippet': snippetElement?.text.trim() ?? '',
                });
              }
            }

            return OpenRouterToolExecutionResult(
              content: jsonEncode({'results': results}),
            );
          } catch (error) {
            return OpenRouterToolExecutionResult(
              content: jsonEncode({'error': 'Search failed: $error'}),
              isError: true,
            );
          }
        },
      ),
      OpenRouterRegisteredTool(
        spec: OpenRouterToolSpec(
          definition: OpenRouterToolDefinition(
            function: OpenRouterToolFunction(
              name: 'open_url',
              description:
                  'Opens a URL and returns the complete HTML content once fully loaded.',
              parameters: const {
                'type': 'object',
                'properties': {
                  'url': {'type': 'string', 'description': 'The URL to fetch.'},
                },
                'required': ['url'],
              },
            ),
          ),
          sensitive: false,
        ),
        execute: (args) async {
          final urlString = (args['url'] as String?)?.trim();

          if (urlString == null || urlString.isEmpty) {
            return const OpenRouterToolExecutionResult(
              content: '{"error":"Missing required argument: url"}',
              isError: true,
            );
          }

          try {
            final uri = Uri.parse(urlString);

            if (!uri.hasScheme || !uri.hasAuthority) {
              return const OpenRouterToolExecutionResult(
                content: '{"error":"Invalid URL format"}',
                isError: true,
              );
            }

            final response = await http.get(uri);

            if (response.statusCode != 200) {
              return OpenRouterToolExecutionResult(
                content: jsonEncode({
                  'error': 'Failed to fetch URL: ${response.statusCode}',
                }),
                isError: true,
              );
            }

            return OpenRouterToolExecutionResult(
              content: jsonEncode({
                'url': urlString,
                'html': response.body,
                'statusCode': response.statusCode,
              }),
            );
          } catch (error) {
            return OpenRouterToolExecutionResult(
              content: jsonEncode({'error': 'Failed to fetch URL: $error'}),
              isError: true,
            );
          }
        },
      ),
    ],
  );
}
