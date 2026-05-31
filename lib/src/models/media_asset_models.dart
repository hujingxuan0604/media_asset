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

enum MediaAssetAction { preview, select, delete, revealInFolder, copyPath }

enum RejectedMediaFileReason {
  unsupportedType,
  imageTooLarge,
  videoTooLarge,
  missing,
  unreadable,
  emptyFile,
}

class RejectedMediaFile {
  final String path;
  final RejectedMediaFileReason reason;

  const RejectedMediaFile({required this.path, required this.reason});
}

class MediaImportValidationResult {
  final List<ValidatedMediaAssetImport> acceptedFiles;
  final List<RejectedMediaFile> rejectedFiles;
  final List<String> duplicatePaths;
  final List<String> duplicateAssetIds;

  const MediaImportValidationResult({
    required this.acceptedFiles,
    required this.rejectedFiles,
    this.duplicatePaths = const [],
    this.duplicateAssetIds = const [],
  });

  List<String> get acceptedPaths {
    return acceptedFiles.map((file) => file.path).toList(growable: false);
  }

  bool get hasAcceptedFiles => acceptedPaths.isNotEmpty;

  bool get hasRejectedFiles => rejectedFiles.isNotEmpty;

  bool get hasDuplicateFiles => duplicatePaths.isNotEmpty;
}

class LocalMediaImportSource {
  final String path;
  final int? fileSize;
  final String? contentHash;
  final bool exists;
  final bool isReadable;

  const LocalMediaImportSource({
    required this.path,
    this.fileSize,
    this.contentHash,
    this.exists = true,
    this.isReadable = true,
  });

  LocalMediaImportSource copyWith({
    int? fileSize,
    String? contentHash,
    bool? exists,
    bool? isReadable,
  }) {
    return LocalMediaImportSource(
      path: path,
      fileSize: fileSize ?? this.fileSize,
      contentHash: contentHash ?? this.contentHash,
      exists: exists ?? this.exists,
      isReadable: isReadable ?? this.isReadable,
    );
  }
}

class ValidatedMediaAssetImport {
  final String path;
  final String name;
  final MediaAssetType type;
  final int fileSize;
  final String? contentHash;

  const ValidatedMediaAssetImport({
    required this.path,
    required this.name,
    required this.type,
    required this.fileSize,
    this.contentHash,
  });

  ValidatedMediaAssetImport copyWith({String? contentHash}) {
    return ValidatedMediaAssetImport(
      path: path,
      name: name,
      type: type,
      fileSize: fileSize,
      contentHash: contentHash ?? this.contentHash,
    );
  }
}

class MediaAsset {
  final String id;
  final String name;
  final String filePath;
  final MediaAssetType type;
  final int fileSize;
  final String? contentHash;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? thumbnailPath;
  final Duration? duration;
  final int? width;
  final int? height;
  final Map<String, Object?> metadata;

  const MediaAsset({
    required this.id,
    required this.name,
    required this.filePath,
    required this.type,
    required this.fileSize,
    required this.createdAt,
    this.contentHash,
    this.updatedAt,
    this.thumbnailPath,
    this.duration,
    this.width,
    this.height,
    this.metadata = const {},
  });

  String? get md5 => contentHash;

  String get extensionLabel {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == name.length - 1) {
      return type.name.toUpperCase();
    }
    return name.substring(dotIndex + 1).toUpperCase();
  }
}
