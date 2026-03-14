import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

class ImportedProjectText {
  const ImportedProjectText({required this.fileName, required this.text});

  final String fileName;
  final String text;
}

class ProjectTextImportService {
  static const Set<String> _pdfExtensions = {'pdf'};
  static const Set<String> _binaryDocumentExtensions = {
    'pdf',
    'doc',
    'docm',
    'xls',
    'xlsb',
    'xlsx',
    'ppt',
    'pptm',
    'pptx',
    'pages',
    'numbers',
    'key',
  };
  static const Map<String, List<String>> _archivedDocumentEntries = {
    'docx': ['word/document.xml'],
    'odt': ['content.xml'],
  };

  Future<String?> extractText(File file) async {
    final extension = path
        .extension(file.path)
        .toLowerCase()
        .replaceFirst('.', '');

    if (_pdfExtensions.contains(extension)) {
      final pdfText = _extractPdfText(file);
      if (pdfText != null) {
        return pdfText;
      }

      return null;
    }

    final archivedDocumentText = await _extractArchivedDocumentText(
      file,
      extension,
    );
    if (archivedDocumentText != null) {
      return archivedDocumentText;
    }

    if (_binaryDocumentExtensions.contains(extension)) {
      return null;
    }

    return _extractPlainText(file);
  }

  String? _extractPdfText(File file) {
    try {
      final document = PdfDocument(inputBytes: file.readAsBytesSync());
      final text = PdfTextExtractor(document).extractText();
      document.dispose();
      return _cleanText(text);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _extractArchivedDocumentText(
    File file,
    String extension,
  ) async {
    final entryNames = _archivedDocumentEntries[extension];
    if (entryNames == null) {
      return null;
    }

    try {
      final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
      final fragments = <String>[];

      for (final entryName in entryNames) {
        final archiveFile = _findArchiveFile(archive, entryName);
        if (archiveFile == null) {
          continue;
        }

        final entryBytes = archiveFile.readBytes();
        if (entryBytes == null) {
          continue;
        }

        final xmlSource = utf8.decode(entryBytes, allowMalformed: true);
        final document = XmlDocument.parse(xmlSource);
        final extracted = document.descendants
            .whereType<XmlText>()
            .map((text) => text.value.trim())
            .where((text) => text.isNotEmpty)
            .join('\n');

        final cleaned = _cleanText(extracted);
        if (cleaned != null) {
          fragments.add(cleaned);
        }
      }

      if (fragments.isEmpty) {
        return null;
      }

      return fragments.join('\n\n');
    } catch (_) {
      return null;
    }
  }

  ArchiveFile? _findArchiveFile(Archive archive, String entryName) {
    for (final entry in archive) {
      if (!entry.isFile) {
        continue;
      }

      if (entry.name == entryName) {
        return entry;
      }
    }

    return null;
  }

  Future<String?> _extractPlainText(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    final candidates = <String>[];
    final hasUtf16LeBom = _hasUtf16Bom(bytes, littleEndian: true);
    final hasUtf16BeBom = _hasUtf16Bom(bytes, littleEndian: false);

    final utf8Bom = _decodeUtf8Bom(bytes);
    if (utf8Bom != null) {
      candidates.add(utf8Bom);
    }

    try {
      candidates.add(utf8.decode(bytes));
    } on FormatException {
      candidates.add(utf8.decode(bytes, allowMalformed: true));
    }

    if (hasUtf16LeBom || _looksLikeUtf16Bytes(bytes, littleEndian: true)) {
      final utf16Le = _decodeUtf16(bytes, littleEndian: true);
      if (utf16Le != null) {
        candidates.add(utf16Le);
      }
    }

    if (hasUtf16BeBom || _looksLikeUtf16Bytes(bytes, littleEndian: false)) {
      final utf16Be = _decodeUtf16(bytes, littleEndian: false);
      if (utf16Be != null) {
        candidates.add(utf16Be);
      }
    }

    candidates.add(latin1.decode(bytes));

    for (final candidate in candidates) {
      final cleaned = _cleanText(candidate);
      if (cleaned != null && _looksLikeText(cleaned)) {
        return cleaned;
      }
    }

    return null;
  }

  String? _decodeUtf8Bom(List<int> bytes) {
    if (bytes.length < 3) {
      return null;
    }
    if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return null;
  }

  String? _decodeUtf16(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length < 2) {
      return null;
    }

    var offset = 0;
    if (bytes.length >= 2) {
      final leading = bytes[0];
      final trailing = bytes[1];
      if (littleEndian && leading == 0xFF && trailing == 0xFE) {
        offset = 2;
      } else if (!littleEndian && leading == 0xFE && trailing == 0xFF) {
        offset = 2;
      }
    }

    final codeUnits = <int>[];
    for (var index = offset; index + 1 < bytes.length; index += 2) {
      final codeUnit = littleEndian
          ? bytes[index] | (bytes[index + 1] << 8)
          : (bytes[index] << 8) | bytes[index + 1];
      codeUnits.add(codeUnit);
    }

    if (codeUnits.isEmpty) {
      return null;
    }

    return String.fromCharCodes(codeUnits);
  }

  bool _hasUtf16Bom(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length < 2) {
      return false;
    }

    if (littleEndian) {
      return bytes[0] == 0xFF && bytes[1] == 0xFE;
    }

    return bytes[0] == 0xFE && bytes[1] == 0xFF;
  }

  bool _looksLikeUtf16Bytes(List<int> bytes, {required bool littleEndian}) {
    if (bytes.length < 8 || bytes.length.isOdd) {
      return false;
    }

    var zeroOnExpectedSide = 0;
    var zeroOnUnexpectedSide = 0;
    var pairs = 0;

    final sampleLength = bytes.length > 512 ? 512 : bytes.length;
    for (var index = 0; index + 1 < sampleLength; index += 2) {
      final first = bytes[index];
      final second = bytes[index + 1];
      pairs += 1;

      if (littleEndian) {
        if (second == 0) {
          zeroOnExpectedSide += 1;
        }
        if (first == 0) {
          zeroOnUnexpectedSide += 1;
        }
      } else {
        if (first == 0) {
          zeroOnExpectedSide += 1;
        }
        if (second == 0) {
          zeroOnUnexpectedSide += 1;
        }
      }
    }

    if (pairs == 0) {
      return false;
    }

    final expectedRatio = zeroOnExpectedSide / pairs;
    final unexpectedRatio = zeroOnUnexpectedSide / pairs;

    return expectedRatio > 0.25 && unexpectedRatio < 0.1;
  }

  String? _cleanText(String? value) {
    if (value == null) {
      return null;
    }

    final normalized = _sanitizeInvalidSurrogates(
      value,
    ).replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();

    if (normalized.isEmpty) {
      return null;
    }

    return normalized;
  }

  String _sanitizeInvalidSurrogates(String value) {
    final codeUnits = value.codeUnits;
    final sanitized = <int>[];

    for (var index = 0; index < codeUnits.length; index += 1) {
      final codeUnit = codeUnits[index];

      if (_isHighSurrogate(codeUnit)) {
        if (index + 1 < codeUnits.length &&
            _isLowSurrogate(codeUnits[index + 1])) {
          sanitized.add(codeUnit);
          sanitized.add(codeUnits[index + 1]);
          index += 1;
          continue;
        }

        sanitized.add(0xFFFD);
        continue;
      }

      if (_isLowSurrogate(codeUnit)) {
        sanitized.add(0xFFFD);
        continue;
      }

      sanitized.add(codeUnit);
    }

    return String.fromCharCodes(sanitized);
  }

  bool _isHighSurrogate(int codeUnit) {
    return codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
  }

  bool _isLowSurrogate(int codeUnit) {
    return codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
  }

  bool _looksLikeText(String text) {
    final sample = text.runes.take(4000);
    var total = 0;
    var suspicious = 0;

    for (final rune in sample) {
      total += 1;

      if (rune == 0x0000 || rune == 0xFFFD) {
        suspicious += 4;
        continue;
      }

      if (rune < 0x20 && rune != 0x09 && rune != 0x0A && rune != 0x0D) {
        suspicious += 2;
      }
    }

    if (total == 0) {
      return false;
    }

    return suspicious / total < 0.15;
  }
}
