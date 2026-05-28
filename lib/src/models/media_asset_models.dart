enum MediaAssetType {
  image,
  video;

  String get label {
    switch (this) {
      case MediaAssetType.image:
        return '图片';
      case MediaAssetType.video:
        return '视频';
    }
  }
}

enum MediaAssetAction { preview, select, delete, download }

enum RejectedMediaFileReason { unsupportedType, imageTooLarge, videoTooLarge }

class RejectedMediaFile {
  final String path;
  final RejectedMediaFileReason reason;

  const RejectedMediaFile({required this.path, required this.reason});
}

class MediaImportValidationResult {
  final List<String> acceptedPaths;
  final List<RejectedMediaFile> rejectedFiles;

  const MediaImportValidationResult({
    required this.acceptedPaths,
    required this.rejectedFiles,
  });

  bool get hasAcceptedFiles => acceptedPaths.isNotEmpty;

  bool get hasRejectedFiles => rejectedFiles.isNotEmpty;
}

class MediaAssetFileCandidate {
  final String path;
  final int? fileSize;

  const MediaAssetFileCandidate({required this.path, this.fileSize});
}

class MediaAsset {
  final String id;
  final String name;
  final String filePath;
  final MediaAssetType type;
  final int fileSize;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? thumbnailPath;
  final Duration? duration;
  final int? width;
  final int? height;
  final Object? extra;

  const MediaAsset({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.fileSize,
    required this.createdAt,
    this.updatedAt,
    this.thumbnailPath,
    this.duration,
    this.width,
    this.height,
    this.extra,
  });

  String get extensionLabel {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return type.name.toUpperCase();
    }
    return name.substring(dotIndex + 1).toUpperCase();
  }
}
