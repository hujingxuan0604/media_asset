/// 素材文件的媒体类型。
enum MediaAssetType {
  /// 图片素材，例如 jpg、png、webp 等文件。
  image,

  /// 视频素材，例如 mp4、mov、webm 等文件。
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

/// 用户可以对单个素材执行的操作。
enum MediaAssetAction {
  /// 打开素材预览。
  preview,

  /// 切换素材的批量选择状态。
  select,

  /// 删除素材。
  delete,

  /// 在系统文件管理器中定位素材文件。
  revealInFolder,
}

/// 本地文件导入时被拒绝的原因。
enum RejectedMediaFileReason {
  /// 文件扩展名不在允许的图片或视频类型中。
  unsupportedType,

  /// 图片文件超过了配置的最大图片大小。
  imageTooLarge,

  /// 视频文件超过了配置的最大视频大小。
  videoTooLarge,

  /// 文件路径不存在。
  missing,

  /// 文件存在但当前进程无法读取。
  unreadable,

  /// 文件大小为 0。
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
