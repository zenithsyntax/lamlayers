import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';

class ImageEditorScreen extends StatelessWidget {
  final Uint8List bytes;
  const ImageEditorScreen({super.key, required this.bytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Image')),
      body: ProImageEditor.memory(
        bytes,
        callbacks: ProImageEditorCallbacks(
          onImageEditingComplete: (editedBytes) async {
            Navigator.pop(context, editedBytes);
            return;
          },
        ),
      ),
    );
  }
}