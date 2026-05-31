import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_asset/media_asset.dart';
import 'package:media_asset/src/controllers/media_asset_controller.dart';

Finder findAssetDrag(String assetId) {
  return find.byWidgetPredicate((widget) {
    return widget is Draggable<MediaAsset> && widget.data?.id == assetId;
  });
}

void main() {
  test(
    'skips duplicate imports by provided content hash when enabled',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'media_asset_test_',
      );
      try {
        final existingFile = File('${directory.path}/existing.png')
          ..writeAsStringSync('same-content');
        final duplicateFile = File('${directory.path}/duplicate.png')
          ..writeAsStringSync('same-content');
        final uniqueFile = File('${directory.path}/unique.png')
          ..writeAsStringSync('unique-content');
        final importedFiles = <ValidatedMediaAssetImport>[];
        final rejectedFiles = <RejectedMediaFile>[];
        final controller = MediaAssetLibraryController(
          config: const MediaAssetLibraryConfig(),
          assets: [
            MediaAsset(
              id: 'existing',
              name: 'existing.png',
              filePath: existingFile.path,
              type: MediaAssetType.image,
              fileSize: existingFile.lengthSync(),
              contentHash: 'f8aeb3a8368e8d146968c49124a2dd98',
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
          onImportFiles: (files) async {
            importedFiles.addAll(files);
          },
          onRejectedFiles: rejectedFiles.addAll,
        );

        final result = await controller.handleImportFiles([
          LocalMediaImportSource(
            path: duplicateFile.path,
            fileSize: duplicateFile.lengthSync(),
            contentHash: 'f8aeb3a8368e8d146968c49124a2dd98',
          ),
          LocalMediaImportSource(
            path: uniqueFile.path,
            fileSize: uniqueFile.lengthSync(),
            contentHash: 'unique-content-hash',
          ),
        ]);

        expect(result.acceptedPaths, [uniqueFile.path]);
        expect(result.duplicatePaths, [duplicateFile.path]);
        expect(result.duplicateAssetIds, ['existing']);
        expect(importedFiles.map((file) => file.path), [uniqueFile.path]);
        expect(importedFiles.single.contentHash, isNotNull);
        expect(rejectedFiles, isEmpty);
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );

  test('does not calculate content hashes inside the library', () async {
    final directory = Directory.systemTemp.createTempSync('media_asset_test_');
    try {
      final existingFile = File('${directory.path}/existing.png')
        ..writeAsStringSync('same-content');
      final duplicateFile = File('${directory.path}/duplicate.png')
        ..writeAsStringSync('same-content');
      final importedFiles = <ValidatedMediaAssetImport>[];
      final controller = MediaAssetLibraryController(
        config: const MediaAssetLibraryConfig(),
        assets: [
          MediaAsset(
            id: 'existing',
            name: 'existing.png',
            filePath: existingFile.path,
            type: MediaAssetType.image,
            fileSize: existingFile.lengthSync(),
            contentHash: 'existing-hash',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        onImportFiles: (files) async {
          importedFiles.addAll(files);
        },
      );

      final result = await controller.handleImportFiles([
        LocalMediaImportSource(
          path: duplicateFile.path,
          fileSize: duplicateFile.lengthSync(),
        ),
      ]);

      expect(result.acceptedPaths, [duplicateFile.path]);
      expect(result.duplicatePaths, isEmpty);
      expect(importedFiles.single.contentHash, isNull);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('rejects missing unreadable and empty local files', () async {
    final controller = MediaAssetLibraryController(
      config: const MediaAssetLibraryConfig(),
    );

    final result = await controller.handleImportFiles([
      const LocalMediaImportSource(path: '/tmp/missing.png', exists: false),
      const LocalMediaImportSource(
        path: '/tmp/unreadable.png',
        exists: true,
        isReadable: false,
      ),
      const LocalMediaImportSource(path: '/tmp/empty.png', fileSize: 0),
    ]);

    expect(result.acceptedFiles, isEmpty);
    expect(result.rejectedFiles.map((file) => file.reason), [
      RejectedMediaFileReason.missing,
      RejectedMediaFileReason.unreadable,
      RejectedMediaFileReason.emptyFile,
    ]);
  });

  test(
    'allows duplicate imports when duplicate prevention is disabled',
    () async {
      final directory = Directory.systemTemp.createTempSync(
        'media_asset_test_',
      );
      try {
        final existingFile = File('${directory.path}/existing.png')
          ..writeAsStringSync('same-content');
        final duplicateFile = File('${directory.path}/duplicate.png')
          ..writeAsStringSync('same-content');
        final importedFiles = <ValidatedMediaAssetImport>[];
        final controller = MediaAssetLibraryController(
          config: const MediaAssetLibraryConfig(
            importConfig: MediaAssetImportConfig(preventDuplicateImport: false),
          ),
          assets: [
            MediaAsset(
              id: 'existing',
              name: 'existing.png',
              filePath: existingFile.path,
              type: MediaAssetType.image,
              fileSize: existingFile.lengthSync(),
              createdAt: DateTime(2026, 1, 1),
            ),
          ],
          onImportFiles: (files) async {
            importedFiles.addAll(files);
          },
        );

        final result = await controller.handleImportFiles([
          LocalMediaImportSource(
            path: duplicateFile.path,
            fileSize: duplicateFile.lengthSync(),
            contentHash: 'f8aeb3a8368e8d146968c49124a2dd98',
          ),
        ]);

        expect(result.acceptedPaths, [duplicateFile.path]);
        expect(result.duplicatePaths, isEmpty);
        expect(result.duplicateAssetIds, isEmpty);
        expect(importedFiles.map((file) => file.path), [duplicateFile.path]);
        expect(importedFiles.single.contentHash, isNotNull);
      } finally {
        directory.deleteSync(recursive: true);
      }
    },
  );

  test('resolves import sources before duplicate checking', () async {
    final directory = Directory.systemTemp.createTempSync('media_asset_test_');
    try {
      final file = File('${directory.path}/same.png')
        ..writeAsStringSync('same-content');
      final importedFiles = <ValidatedMediaAssetImport>[];
      final controller = MediaAssetLibraryController(
        config: const MediaAssetLibraryConfig(),
        assets: [
          MediaAsset(
            id: 'existing',
            name: 'same.png',
            filePath: file.path,
            type: MediaAssetType.image,
            fileSize: file.lengthSync(),
            contentHash: 'resolved-hash',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        onResolveImportSources: (sources) async {
          return sources
              .map((source) => source.copyWith(contentHash: 'resolved-hash'))
              .toList(growable: false);
        },
        onImportFiles: (files) async {
          importedFiles.addAll(files);
        },
      );

      final result = await controller.handleImportFiles([
        LocalMediaImportSource(path: file.path, fileSize: file.lengthSync()),
      ]);

      expect(result.acceptedFiles, isEmpty);
      expect(result.duplicatePaths, [file.path]);
      expect(result.duplicateAssetIds, ['existing']);
      expect(importedFiles, isEmpty);
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  testWidgets('renders an empty media asset library', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            assets: [],
            config: MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
          ),
        ),
      ),
    );

    expect(find.text('拖入图片或视频'), findsOneWidget);
    expect(find.byIcon(Icons.perm_media_outlined), findsOneWidget);
  });

  testWidgets('removes selected ids that no longer exist in assets', (
    tester,
  ) async {
    Set<String>? emittedSelection;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            selectedAssetIds: const {'asset', 'next'},
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
              MediaAsset(
                id: 'next',
                name: 'next.png',
                filePath: '/tmp/next.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
            onSelectionChanged: (ids) {
              emittedSelection = ids;
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('已选择 2 / 2'), findsOneWidget);
    expect(find.byIcon(Icons.check_box_outlined), findsWidgets);
    expect(emittedSelection, isNull);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            selectedAssetIds: const {'asset', 'next'},
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onSelectionChanged: (ids) {
              emittedSelection = ids;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(emittedSelection, {'asset'});
  });

  testWidgets('builds large grids lazily', (tester) async {
    final assets = List.generate(500, (index) {
      return MediaAsset(
        id: 'asset-$index',
        name: 'asset-$index.png',
        filePath: '/tmp/asset-$index.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 1),
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: assets,
          ),
        ),
      ),
    );

    expect(find.byType(Draggable<MediaAsset>), findsWidgets);
    expect(find.byType(Draggable<MediaAsset>).evaluate().length, lessThan(500));
  });

  testWidgets('can shrink wrap inside an external scroll view', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaAssetLibrary(
              config: const MediaAssetLibraryConfig(
                layout: MediaAssetLayoutConfig(
                  showToolbar: false,
                  shrinkWrap: true,
                ),
              ),
              assets: [
                MediaAsset(
                  id: 'asset',
                  name: 'asset.png',
                  filePath: '/tmp/asset.png',
                  type: MediaAssetType.image,
                  fileSize: 0,
                  createdAt: DateTime(2026, 1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(findAssetDrag('asset'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passes tile extent to custom tiles', (tester) async {
    double? tileExtent;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            child: MediaAssetLibrary(
              config: const MediaAssetLibraryConfig(
                layout: MediaAssetLayoutConfig(showToolbar: false),
              ),
              assets: [
                MediaAsset(
                  id: 'asset',
                  name: 'asset.png',
                  filePath: '/tmp/asset.png',
                  type: MediaAssetType.image,
                  fileSize: 0,
                  createdAt: DateTime(2026, 1, 1),
                ),
              ],
              tileBuilder: (context, asset, state) {
                tileExtent = state.tileExtent;
                return SizedBox(width: state.tileExtent, child: Text(asset.id));
              },
            ),
          ),
        ),
      ),
    );

    expect(tileExtent, isNotNull);
    expect(tileExtent, greaterThan(0));
    expect(find.text('asset'), findsOneWidget);
  });

  testWidgets('shows default local import button when import callback exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            assets: const [],
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            onImportFiles: (files) async {},
          ),
        ),
      ),
    );

    expect(find.text('导入素材'), findsOneWidget);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
  });

  testWidgets('orders assets by created time descending by default', (
    tester,
  ) async {
    final older = DateTime(2026, 1, 1);
    final newer = DateTime(2026, 1, 2);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [
              MediaAsset(
                id: 'older',
                name: 'older.png',
                filePath: '/tmp/older.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: older,
              ),
              MediaAsset(
                id: 'newer',
                name: 'newer.png',
                filePath: '/tmp/newer.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: newer,
              ),
            ],
          ),
        ),
      ),
    );

    final newerPosition = tester.getTopLeft(findAssetDrag('newer'));
    final olderPosition = tester.getTopLeft(findAssetDrag('older'));

    expect(newerPosition.dx, lessThan(olderPosition.dx));
  });

  testWidgets('orders assets by configured sort mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(
                showToolbar: false,
                sortMode: MediaAssetSortMode.nameAsc,
              ),
            ),
            assets: [
              MediaAsset(
                id: 'z',
                name: 'z.png',
                filePath: '/tmp/z.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
              MediaAsset(
                id: 'a',
                name: 'a.png',
                filePath: '/tmp/a.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
          ),
        ),
      ),
    );

    final aPosition = tester.getTopLeft(findAssetDrag('a'));
    final zPosition = tester.getTopLeft(findAssetDrag('z'));

    expect(aPosition.dx, lessThan(zPosition.dx));
  });

  testWidgets('orders assets by custom comparator when provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(
                showToolbar: false,
                sortComparator: (a, b) => a.fileSize.compareTo(b.fileSize),
              ),
            ),
            assets: [
              MediaAsset(
                id: 'large',
                name: 'large.png',
                filePath: '/tmp/large.png',
                type: MediaAssetType.image,
                fileSize: 200,
                createdAt: DateTime(2026, 1, 1),
              ),
              MediaAsset(
                id: 'small',
                name: 'small.png',
                filePath: '/tmp/small.png',
                type: MediaAssetType.image,
                fileSize: 100,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
          ),
        ),
      ),
    );

    final smallPosition = tester.getTopLeft(findAssetDrag('small'));
    final largePosition = tester.getTopLeft(findAssetDrag('large'));

    expect(smallPosition.dx, lessThan(largePosition.dx));
  });

  testWidgets('shows default context menu without a builder', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    MediaAsset? revealedAsset;
    MediaAsset? deletedAsset;
    final actions = <MediaAssetAction>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onRevealAssetInFolder: (asset) {
              revealedAsset = asset;
            },
            onDeleteAsset: (asset) {
              deletedAsset = asset;
            },
            onAssetAction: (action, asset) {
              actions.add(action);
            },
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('预览'), findsOneWidget);
    expect(find.text('选择'), findsOneWidget);
    expect(find.text('在文件夹中显示'), findsOneWidget);
    expect(find.text('复制路径'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('复制路径'));
    await tester.pumpAndSettle();

    expect(copiedText, '/tmp/asset.png');
    expect(actions, [MediaAssetAction.copyPath]);
    expect(find.text('已复制文件路径'), findsOneWidget);

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('在文件夹中显示'));
    await tester.pumpAndSettle();

    expect(revealedAsset?.id, 'asset');

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(deletedAsset?.id, 'asset');
  });

  testWidgets('customizes default action labels and messages', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
              text: MediaAssetTextConfig(
                copyPathActionLabel: '复制本地路径',
                copyPathSuccessMessage: '路径已复制',
              ),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制本地路径'));
    await tester.pumpAndSettle();

    expect(copiedText, '/tmp/asset.png');
    expect(find.text('路径已复制'), findsOneWidget);
  });

  testWidgets('hides disabled default actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
              interaction: MediaAssetInteractionConfig(
                enabledActions: {MediaAssetAction.preview},
              ),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onDeleteAsset: (_) {},
            onRevealAssetInFolder: (_) {},
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('预览'), findsOneWidget);
    expect(find.text('选择'), findsNothing);
    expect(find.text('在文件夹中显示'), findsNothing);
    expect(find.text('复制路径'), findsNothing);
    expect(find.text('删除'), findsNothing);
  });

  testWidgets('reports default copy action errors', (tester) async {
    MediaAssetAction? errorAction;
    List<MediaAsset>? errorAssets;

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'copy_failed');
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onActionError: (action, assets, error, stackTrace) {
              errorAction = action;
              errorAssets = assets;
            },
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('复制路径'));
    await tester.pumpAndSettle();

    expect(errorAction, MediaAssetAction.copyPath);
    expect(errorAssets?.single.id, 'asset');
  });

  testWidgets('copies selected asset paths from toolbar', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText =
              (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    final actions = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            selectedAssetIds: const {'a', 'b'},
            assets: [
              MediaAsset(
                id: 'a',
                name: 'a.png',
                filePath: '/tmp/a.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
              MediaAsset(
                id: 'b',
                name: 'b.png',
                filePath: '/tmp/b.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
            onAssetAction: (action, asset) {
              actions.add('${action.name}:${asset.id}');
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.content_copy_outlined));
    await tester.pumpAndSettle();

    expect(copiedText, '/tmp/b.png\n/tmp/a.png');
    expect(actions, ['copyPath:b', 'copyPath:a']);
    expect(find.text('已复制 2 个文件路径'), findsOneWidget);
  });

  testWidgets('hides context menu when disabled', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
              interaction: MediaAssetInteractionConfig(
                enableContextMenu: false,
              ),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('预览'), findsNothing);
    expect(find.text('复制路径'), findsNothing);
  });

  testWidgets('shows custom context menu from builder and wires actions', (
    tester,
  ) async {
    MediaAsset? deletedAsset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onDeleteAsset: (asset) {
              deletedAsset = asset;
            },
            menuBuilder: (context, asset, state, controller) {
              return Material(
                child: TextButton(
                  onPressed: controller.delete,
                  child: const Text('自定义删除'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('自定义删除'), findsOneWidget);

    await tester.tap(find.text('自定义删除'));
    await tester.pumpAndSettle();

    expect(deletedAsset?.id, 'asset');
    expect(find.text('自定义删除'), findsNothing);
  });

  testWidgets('shows delete button only while hovering the thumbnail', (
    tester,
  ) async {
    MediaAsset? deletedAsset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [
              MediaAsset(
                id: 'asset',
                name: 'asset.png',
                filePath: '/tmp/asset.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onDeleteAsset: (asset) {
              deletedAsset = asset;
            },
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('asset.png'), findsNothing);
    expect(find.text('0 B'), findsNothing);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(findAssetDrag('asset')));
    await tester.pump();

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.text('asset.png'), findsOneWidget);
    expect(find.text('0 B'), findsOneWidget);
    expect(
      tester.getCenter(find.byIcon(Icons.close_rounded)).dy,
      lessThan(tester.getCenter(findAssetDrag('asset')).dy),
    );

    await mouse.moveTo(tester.getCenter(find.byIcon(Icons.close_rounded)));
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await mouse.down(tester.getCenter(find.byIcon(Icons.close_rounded)));
    await mouse.up();
    await tester.pump();

    expect(deletedAsset?.id, 'asset');
  });

  testWidgets('drags imported assets to a host drag target', (tester) async {
    MediaAsset? receivedAsset;
    final asset = MediaAsset(
      id: 'asset',
      name: 'asset.png',
      filePath: '/tmp/asset.png',
      type: MediaAssetType.image,
      fileSize: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              SizedBox(
                width: 240,
                child: MediaAssetLibrary(
                  config: const MediaAssetLibraryConfig(
                    layout: MediaAssetLayoutConfig(showToolbar: false),
                  ),
                  assets: [asset],
                ),
              ),
              DragTarget<MediaAsset>(
                onAcceptWithDetails: (details) {
                  receivedAsset = details.data;
                },
                builder: (context, candidateData, rejectedData) {
                  return const SizedBox(
                    key: ValueKey('module-target'),
                    width: 240,
                    height: 160,
                    child: Text('其他模块'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(findAssetDrag('asset')),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();

    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('module-target'))),
    );
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(receivedAsset?.id, 'asset');
  });

  testWidgets('uses custom drag feedback builder', (tester) async {
    final asset = MediaAsset(
      id: 'asset',
      name: 'asset.png',
      filePath: '/tmp/asset.png',
      type: MediaAssetType.image,
      fileSize: 0,
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
            ),
            assets: [asset],
            dragFeedbackBuilder: (context, asset, state) {
              return Material(
                child: SizedBox(
                  key: const ValueKey('custom-feedback'),
                  width: state.tileExtent,
                  height: 32,
                  child: Text(asset.id),
                ),
              );
            },
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(findAssetDrag('asset')),
    );
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();

    expect(find.byKey(const ValueKey('custom-feedback')), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 50));
  });
}
