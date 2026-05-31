import 'dart:io';

import 'package:flutter/material.dart';

import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';

class ImageAssetPreview extends StatelessWidget {
  final MediaAsset asset;
  final TransformationController transformationController;
  final double minScale;
  final double maxScale;
  final String loadFailureText;

  const ImageAssetPreview({
    super.key,
    required this.asset,
    required this.transformationController,
    required this.minScale,
    required this.maxScale,
    required this.loadFailureText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    final file = File(asset.filePath);

    return Container(
      decoration: BoxDecoration(
        color: theme.elevatedSurface(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InteractiveViewer(
        transformationController: transformationController,
        minScale: minScale,
        maxScale: maxScale,
        panEnabled: true,
        scaleEnabled: true,
        boundaryMargin: const EdgeInsets.all(240),
        child: SizedBox.expand(
          child: Center(
            child: file.existsSync()
                ? Image.file(
                    file,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _ImageLoadFailure(message: loadFailureText);
                    },
                  )
                : _ImageLoadFailure(message: loadFailureText),
          ),
        ),
      ),
    );
  }
}

class _ImageLoadFailure extends StatelessWidget {
  final String message;

  const _ImageLoadFailure({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.broken_image_outlined,
          size: 32,
          color: theme.mutedText(context),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(fontSize: 12, color: theme.mutedText(context)),
        ),
      ],
    );
  }
}
