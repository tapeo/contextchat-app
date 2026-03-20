import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;

final urlImportProvider = NotifierProvider<UrlImportNotifier, UrlImportState>(
  () => UrlImportNotifier(),
);

class UrlImportState {
  final bool isLoading;

  const UrlImportState({this.isLoading = false});

  UrlImportState copyWith({bool? isLoading}) {
    return UrlImportState(isLoading: isLoading ?? this.isLoading);
  }
}

class UrlImportNotifier extends Notifier<UrlImportState> {
  @override
  UrlImportState build() {
    return const UrlImportState();
  }

  Future<UrlImportResult> importFromUrl(String url) async {
    if (url.isEmpty) {
      return UrlImportResult.failure('URL cannot be empty');
    }

    state = state.copyWith(isLoading: true);

    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) {
        return UrlImportResult.failure('Invalid URL format');
      }

      final response = await http.get(uri);
      if (response.statusCode != 200) {
        return UrlImportResult.failure(
          'Failed to fetch URL: ${response.statusCode}',
        );
      }

      final text = _stripHtml(response.body);

      if (text.isEmpty) {
        return UrlImportResult.failure('No readable text found at URL');
      }

      return UrlImportResult.success(text: text, url: url);
    } catch (error) {
      return UrlImportResult.failure('Failed to import from URL: $error');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  String _stripHtml(String html) {
    final document = parse(html);
    for (final script in document.querySelectorAll('script, style')) {
      script.remove();
    }
    final buffer = StringBuffer();
    _extractText(document.body!, buffer);
    return buffer.toString().trim();
  }

  void _extractText(Node node, StringBuffer buffer) {
    if (node.nodeType == Node.TEXT_NODE) {
      buffer.write(node.text);
    } else {
      for (final child in node.nodes) {
        _extractText(child, buffer);
      }
      if (node.nodeType == Node.ELEMENT_NODE) {
        final tag = (node as Element).localName?.toLowerCase() ?? '';
        if (_isBlockTag(tag)) buffer.write('\n');
      }
    }
  }

  bool _isBlockTag(String tag) =>
      tag == 'p' ||
      tag == 'br' ||
      tag.startsWith('h') ||
      tag == 'li' ||
      tag == 'tr' ||
      tag == 'article' ||
      tag == 'section' ||
      tag == 'blockquote' ||
      tag == 'ul' ||
      tag == 'ol' ||
      tag == 'table';
}

class UrlImportResult {
  final bool isSuccess;
  final String? text;
  final String? url;
  final String? error;

  const UrlImportResult._({
    required this.isSuccess,
    this.text,
    this.url,
    this.error,
  });

  factory UrlImportResult.success({required String text, required String url}) {
    return UrlImportResult._(isSuccess: true, text: text, url: url);
  }

  factory UrlImportResult.failure(String error) {
    return UrlImportResult._(isSuccess: false, error: error);
  }
}
