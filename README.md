# media_asset

A configurable Flutter desktop package for managing image and video assets.

It provides:

- image and video asset models
- desktop drag-and-drop import validation
- grid, tile, toolbar, and empty states
- image preview with zoom and navigation shortcuts
- video preview with playback, seek controls, and navigation shortcuts
- callback-based import, delete, download, and selection integration

## Usage

Import the public entrypoint only:

```dart
import 'package:media_asset/media_asset.dart';
```

Render the library:

```dart
MediaAssetLibrary(
  assets: assets,
  selectedAssetIds: selectedAssetIds,
  onSelectionChanged: (ids) {
    setState(() => selectedAssetIds = ids);
  },
  onImportFiles: (paths) async {
    // Copy files, persist metadata, then rebuild with new MediaAsset values.
  },
  onRejectedFiles: (files) {
    // Show unsupported type or file-size errors in the host app.
  },
  onDeleteAsset: (asset) {
    // Delete in the host app, then rebuild.
  },
  menuBuilder: (context, asset, state, controller) {
    // Return your own context-menu widget. No menu is shown when omitted.
    return YourAssetMenu(controller: controller);
  },
)
```

Set global defaults with `MediaAssetLibraryScope`, or pass a component-level
`MediaAssetLibraryConfig` directly to `MediaAssetLibrary`.

Video preview uses `video_player` with `fvp` registered for Windows, Linux, and
macOS from inside the preview widget.

## Example

A runnable example is available in `example/`.

```bash
cd example
flutter pub get
flutter run -d macos
```

Replace `macos` with `windows` or `linux` for other desktop targets.

The example demonstrates:

- using `MediaAssetLibraryScope` for global config
- drag-and-drop import with file type and size validation
- converting file paths to `MediaAsset`
- selection, batch delete, single delete, and download callbacks
- previewing local images and videos
