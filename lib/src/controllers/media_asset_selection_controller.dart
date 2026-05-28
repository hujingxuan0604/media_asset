import 'package:flutter/foundation.dart';

class MediaAssetSelectionController extends ChangeNotifier {
  Set<String> _selectedAssetIds;

  MediaAssetSelectionController({Set<String> selectedAssetIds = const {}})
    : _selectedAssetIds = Set<String>.from(selectedAssetIds);

  Set<String> get selectedAssetIds =>
      Set<String>.unmodifiable(_selectedAssetIds);

  bool isSelected(String assetId) => _selectedAssetIds.contains(assetId);

  void replace(Set<String> selectedAssetIds) {
    _selectedAssetIds = Set<String>.from(selectedAssetIds);
    notifyListeners();
  }

  Set<String> toggle(String assetId) {
    final next = Set<String>.from(_selectedAssetIds);
    if (!next.add(assetId)) {
      next.remove(assetId);
    }
    replace(next);
    return selectedAssetIds;
  }

  Set<String> selectOnly(String assetId) {
    replace({assetId});
    return selectedAssetIds;
  }

  Set<String> selectAll(Iterable<String> assetIds) {
    replace(assetIds.toSet());
    return selectedAssetIds;
  }

  Set<String> invert(Iterable<String> assetIds) {
    final next = <String>{};
    for (final id in assetIds) {
      if (!_selectedAssetIds.contains(id)) {
        next.add(id);
      }
    }
    replace(next);
    return selectedAssetIds;
  }

  Set<String> clear() {
    replace({});
    return selectedAssetIds;
  }
}
