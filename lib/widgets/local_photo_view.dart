import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/photo_service.dart';

class LocalPhotoView extends StatefulWidget {
  const LocalPhotoView({super.key, required this.assetId, this.size = 100});
  final String assetId;
  final double size;
  @override
  State<LocalPhotoView> createState() => _LocalPhotoViewState();
}

class _LocalPhotoViewState extends State<LocalPhotoView> {
  late Future<Uint8List?> _bytes = PhotoService.thumbnail(widget.assetId);
  @override
  void didUpdateWidget(LocalPhotoView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetId != widget.assetId) {
      _bytes = PhotoService.thumbnail(widget.assetId);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.size,
    height: widget.size,
    child: FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.data == null) {
          return const ColoredBox(
            color: Color(0xFFE8ECE7),
            child: Center(
              child: Tooltip(
                message: 'Photo unavailable. Check selected photo access or download it in Photos.',
                child: Icon(Icons.image_not_supported_outlined),
              ),
            ),
          );
        }
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
      },
    ),
  );
}
