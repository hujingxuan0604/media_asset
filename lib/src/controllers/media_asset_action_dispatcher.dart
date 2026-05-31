import '../models/media_asset_models.dart';

typedef MediaAssetActionCallback =
    void Function(MediaAssetAction action, MediaAsset asset);
typedef MediaAssetActionErrorCallback =
    void Function(
      MediaAssetAction action,
      List<MediaAsset> assets,
      Object error,
      StackTrace stackTrace,
    );

class MediaAssetActionDispatcher {
  final MediaAssetActionCallback? onAssetAction;

  const MediaAssetActionDispatcher({this.onAssetAction});

  void dispatch(MediaAssetAction action, MediaAsset asset) {
    onAssetAction?.call(action, asset);
  }
}
