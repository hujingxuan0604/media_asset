import 'package:flutter/foundation.dart';

import '../models/media_asset_models.dart';

class MediaAssetPreviewController extends ChangeNotifier {
  static const double minScale = 0.6;
  static const double maxScale = 5.0;

  List<MediaAsset> _assets;
  int _currentIndex;
  double _imageScale = 1;

  MediaAssetPreviewController({
    required List<MediaAsset> assets,
    required MediaAsset initialAsset,
  }) : _assets = List<MediaAsset>.unmodifiable(
         _buildAssets(assets, initialAsset),
       ),
       _currentIndex = _resolveInitialIndex(assets, initialAsset);

  List<MediaAsset> get assets => _assets;

  int get currentIndex => _currentIndex;

  int get count => _assets.length;

  bool get canNavigate => _assets.length > 1;

  double get imageScale => _imageScale;

  MediaAsset get currentAsset => _assets[_currentIndex];

  void replaceAssets(List<MediaAsset> assets, MediaAsset initialAsset) {
    _assets = List<MediaAsset>.unmodifiable(_buildAssets(assets, initialAsset));
    _currentIndex = _resolveInitialIndex(_assets, initialAsset);
    _imageScale = 1;
    notifyListeners();
  }

  void openAt(int index) {
    if (_assets.isEmpty) {
      return;
    }
    _currentIndex = (index + _assets.length) % _assets.length;
    _imageScale = 1;
    notifyListeners();
  }

  void next() {
    openAt(_currentIndex + 1);
  }

  void previous() {
    openAt(_currentIndex - 1);
  }

  void zoomBy(double factor) {
    _imageScale = (_imageScale * factor).clamp(minScale, maxScale).toDouble();
    notifyListeners();
  }

  void resetZoom() {
    _imageScale = 1;
    notifyListeners();
  }

  static List<MediaAsset> _buildAssets(
    List<MediaAsset> assets,
    MediaAsset initialAsset,
  ) {
    final mediaAssets = assets
        .where(
          (asset) =>
              asset.type == MediaAssetType.image ||
              asset.type == MediaAssetType.video,
        )
        .toList(growable: true);

    final containsInitial = mediaAssets.any(
      (asset) => asset.id == initialAsset.id,
    );
    if (!containsInitial) {
      mediaAssets.insert(0, initialAsset);
    }
    return mediaAssets;
  }

  static int _resolveInitialIndex(
    List<MediaAsset> assets,
    MediaAsset initialAsset,
  ) {
    final mediaAssets = _buildAssets(assets, initialAsset);
    final index = mediaAssets.indexWhere(
      (asset) => asset.id == initialAsset.id,
    );
    return index < 0 ? 0 : index;
  }
}
