import 'package:cross_file/cross_file.dart';
import 'package:file_selector/file_selector.dart' show XTypeGroup, openFiles;

import '../config/media_asset_config.dart';

class LocalFilePickerService {
  const LocalFilePickerService();

  Future<List<XFile>> pickFiles(MediaAssetFileTypeConfig config) {
    return openFiles(acceptedTypeGroups: acceptedTypeGroups(config));
  }

  List<XTypeGroup> acceptedTypeGroups(MediaAssetFileTypeConfig config) {
    return [
      if (config.imageExtensions.isNotEmpty)
        XTypeGroup(
          label: 'Images',
          extensions: config.imageExtensions.toList(growable: false),
        ),
      if (config.videoExtensions.isNotEmpty)
        XTypeGroup(
          label: 'Videos',
          extensions: config.videoExtensions.toList(growable: false),
        ),
    ];
  }
}
