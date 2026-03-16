import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class FileUtils {
  static Future<void> revealInFileManager(String path) async {
    final file = File(path);
    final directory = Directory(path);
    final exists = await file.exists() || await directory.exists();

    if (!exists) return;

    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer.exe', ['/select,', path]);
    } else if (Platform.isLinux) {
      await Process.run('dbus-send', [
        '--session',
        '--dest=org.freedesktop.FileManager1',
        '--type=method_call',
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1.ShowItems',
        'array:string:file://$path',
        'string:""'
      ]);
    } else {
      final parentPath = (await FileSystemEntity.isDirectory(path))
          ? path
          : File(path).parent.path;
      await launchUrl(Uri.file(parentPath));
    }
  }

  static Future<void> openFolder(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer.exe', [path]);
    } else {
      await launchUrl(Uri.file(path));
    }
  }
}
