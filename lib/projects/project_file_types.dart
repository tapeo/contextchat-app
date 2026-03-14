import 'package:path/path.dart' as path;

const Map<String, String> supportedProjectImageMimeTypes = {
  'png': 'image/png',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'webp': 'image/webp',
  'gif': 'image/gif',
};

const List<String> supportedProjectImageExtensions = [
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
];

String? imageMimeTypeForFileName(String fileName) {
  final extension = path.extension(fileName).toLowerCase();
  if (extension.isEmpty) {
    return null;
  }

  return supportedProjectImageMimeTypes[extension.substring(1)];
}

bool isSupportedImageFileName(String fileName) {
  return imageMimeTypeForFileName(fileName) != null;
}
