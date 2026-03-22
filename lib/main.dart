import 'dart:io';

import 'package:contextchat/app/app.dart';
import 'package:contextchat/database/database.service.dart';
import 'package:contextchat/file_storage/file_storage.provider.dart';
import 'package:contextchat/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final container = await providerContainer();

  runApp(UncontrolledProviderScope(container: container, child: _Main()));
}

Future<ProviderContainer> providerContainer() async {
  final debug = kDebugMode;

  final fileStorage = FileStorage();
  final database = DatabaseService();

  final appDir = await getApplicationSupportDirectory();
  final storageRoot = debug ? Directory('${appDir.path}/debug') : appDir;

  await fileStorage.initialize(storageRoot);

  final customPath = fileStorage.getString('storage_path');
  final databaseRoot = customPath != null ? Directory(customPath) : storageRoot;

  await database.initialize(databaseRoot);

  final container = ProviderContainer(
    overrides: [
      fileStorageProvider.overrideWithValue(fileStorage),
      databaseProvider.overrideWithValue(database),
    ],
  );

  return container;
}

class _Main extends StatelessWidget {
  const _Main();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: App(),
    );
  }
}
