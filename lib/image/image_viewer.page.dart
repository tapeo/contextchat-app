import 'dart:convert';

import 'package:contextchat/components/custom_app_bar.dart';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatelessWidget {
  const ImageViewerPage({
    super.key,
    required this.base64Data,
    required this.mimeType,
  });

  final String base64Data;
  final String mimeType;

  @override
  Widget build(BuildContext context) {
    final bytes = base64Decode(base64Data);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: CustomAppBar(
        showBackButton: true,
        title: 'Image',
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
