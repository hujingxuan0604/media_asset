# media_asset

A configurable Flutter desktop package for managing image and video assets.

It provides:

- image and video asset models
- desktop drag-and-drop import validation
- local desktop file picking through the same import pipeline
- duplicate prevention using host-provided content hashes
- dragging imported assets into host app modules with `DragTarget<MediaAsset>`
- grid, tile, toolbar, and empty states
- image preview with zoom and navigation shortcuts
- video preview with playback, seek controls, and navigation shortcuts
- callback-based import, delete, reveal-in-folder, and selection integration
- default desktop context menu with preview, selection, reveal-in-folder, and
  delete actions

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
  onImportFiles: (candidates) async {
    // Copy files, persist metadata, then rebuild with new MediaAsset values.
    // Each candidate includes path, name, type, fileSize, and optional contentHash.
  },
  onResolveImportSources: (sources) async {
    // Optional: attach host-calculated md5/contentHash before validation and
    // duplicate checking. The package does not calculate hashes internally.
    return sources;
  },
  onRejectedFiles: (files) {
    // Show unsupported type or file-size errors in the host app.
  },
  onDeleteAsset: (asset) {
    // Delete in the host app, then rebuild.
  },
  onRevealAssetInFolder: (asset) {
    // Reveal the local file in Explorer/Finder/file manager.
  },
  menuBuilder: (context, asset, state, controller) {
    // Optional: replace the built-in desktop context menu.
    return YourAssetMenu(controller: controller);
  },
)
```

Receive an imported asset elsewhere in your app:

```dart
DragTarget<MediaAsset>(
  onAcceptWithDetails: (details) {
    final asset = details.data;
    // Attach asset to another module in the host app.
  },
  builder: (context, candidateData, rejectedData) {
    return YourModuleSurface();
  },
)
```

Set global defaults with `MediaAssetLibraryScope`, or pass a component-level
`MediaAssetLibraryConfig` directly to `MediaAssetLibrary`.

When `onImportFiles` is provided, the built-in import button opens the desktop
file picker and then uses the same validation, duplicate, and callback pipeline
as drag-and-drop. Pass `onAddPressed` only when the host app needs to replace
that default behavior.

Context-menu behavior lives under `MediaAssetInteractionConfig`. Its
`enableContextMenu` option controls the built-in right-click menu. When
`menuBuilder` is omitted, the library shows the default desktop menu. Provide
`menuBuilder` only when the host app needs a custom menu surface.

Dropped files are checked for duplicates only when the host app provides
`contentHash` values on existing `MediaAsset`s and incoming import sources. Use
`onResolveImportSources` to attach host-calculated md5/content hashes before
validation and duplicate checking. The package never calculates hashes
internally, so large local videos are not read just for duplicate detection.
Matched duplicate files are reported through the duplicate summary and are not
included in rejected-file callbacks. Disable duplicate prevention with
`MediaAssetLibraryConfig(importConfig: MediaAssetImportConfig(preventDuplicateImport: false))`.
Customize the duplicate summary text with
`MediaAssetTextConfig(duplicateImportMessageTemplate: ...)`; it supports
`{imported}` and `{duplicate}` placeholders.

The default sort is `MediaAssetSortMode.createdAtDesc`. Set `sortMode` to
`MediaAssetLibraryConfig(layout: MediaAssetLayoutConfig(sortMode: ...))`. The
available modes are `manual`, `createdAtAsc`, `nameAsc`, `nameDesc`,
`fileSizeAsc`, `fileSizeDesc`, and `typeAsc`. Use `sortComparator` for host
specific ordering such as natural filename sorting or type grouping.

Grid layout is configured with desktop-level options such as `density` and
`thumbnailSize` under `MediaAssetLayoutConfig`.

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
- drag-and-drop and file-picker import with file type and size validation
- duplicate file prevention based on host-provided hashes
- dragging imported assets into another module panel
- converting file paths to `MediaAsset`
- default and custom context menus
- selection, batch delete, single delete, and reveal-in-folder actions
- previewing local images and videos
