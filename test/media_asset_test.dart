import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_asset/media_asset.dart';
import 'package:media_asset/src/controllers/media_asset_controller.dart';

Finder findAssetDrag(String assetId) {
  return find.byWidgetPredicate((widget) {
    return widget is Draggable<MediaAsset> && widget.data?.id == assetId;
  });
}

class _StatefulAssetTile extends StatefulWidget {
  final MediaAsset asset;

  const _StatefulAssetTile({required this.asset});

  @override
  State<_StatefulAssetTile> createState() => _StatefulAssetTileState();
}

class _StatefulAssetTileState extends State<_StatefulAssetTile> {
  late final String initialAssetId = widget.asset.id;

  @override
  Widget build(BuildContext context) {
    return Text('$initialAssetId:${widget.asset.id}');
  }
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
    expect(tester.getSize(find.byType(AnimatedContainer)).height, 210);
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

    expect(find.text('素材库'), findsOneWidget);
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
            height: 360,
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

  testWidgets('preserves tile state for remaining assets after deletion', (
    tester,
  ) async {
    var assets = [
      MediaAsset(
        id: 'asset-a',
        name: 'a.png',
        filePath: '/tmp/a.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 1),
      ),
      MediaAsset(
        id: 'asset-b',
        name: 'b.png',
        filePath: '/tmp/b.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 2),
      ),
      MediaAsset(
        id: 'asset-c',
        name: 'c.png',
        filePath: '/tmp/c.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 3),
      ),
    ];

    Widget buildLibrary() {
      return MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
              interaction: MediaAssetInteractionConfig(
                enableAssetDragging: false,
              ),
            ),
            assets: assets,
            tileBuilder: (context, asset, state) =>
                _StatefulAssetTile(asset: asset),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildLibrary());

    expect(find.text('asset-a:asset-a'), findsOneWidget);
    expect(find.text('asset-b:asset-b'), findsOneWidget);
    expect(find.text('asset-c:asset-c'), findsOneWidget);

    assets = assets.skip(1).toList(growable: false);
    await tester.pumpWidget(buildLibrary());

    expect(find.text('asset-a:asset-b'), findsNothing);
    expect(find.text('asset-b:asset-b'), findsOneWidget);
    expect(find.text('asset-c:asset-c'), findsOneWidget);
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

  testWidgets(
    'shows default local import button with built-in import enabled',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaAssetLibrary(
              assets: const [],
              config: const MediaAssetLibraryConfig(
                layout: MediaAssetLayoutConfig(showToolbar: false),
              ),
            ),
          ),
        ),
      );

      expect(find.text('导入素材'), findsOneWidget);
      expect(find.byIcon(Icons.add_photo_alternate_outlined), findsOneWidget);
    },
  );

  testWidgets('hides built-in import entry points when drag-drop is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            assets: [],
            config: MediaAssetLibraryConfig(
              interaction: MediaAssetInteractionConfig(enableDragDrop: false),
            ),
          ),
        ),
      ),
    );

    expect(find.text('导入素材'), findsNothing);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsNothing);
    expect(find.text('拖入图片或视频'), findsOneWidget);
  });

  testWidgets('hides empty import button without affecting toolbar import', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            assets: const [],
            showEmptyImportButton: false,
            onImportFiles: (files) async {},
          ),
        ),
      ),
    );

    expect(find.text('导入素材'), findsNothing);
    expect(find.byIcon(Icons.add_photo_alternate_outlined), findsNothing);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.text('拖入图片或视频'), findsOneWidget);
  });

  testWidgets('supports simple height and internal header collapse', (
    tester,
  ) async {
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
            title: '三视图',
            assets: [asset],
            height: 180,
            collapsible: true,
          ),
        ),
      ),
    );

    expect(find.text('三视图'), findsOneWidget);
    expect(findAssetDrag('asset'), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);

    await tester.tap(find.text('三视图'));
    await tester.pump();

    expect(findAssetDrag('asset'), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('keeps assets in caller-provided order', (tester) async {
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
                createdAt: DateTime(2026, 1, 1),
              ),
              MediaAsset(
                id: 'newer',
                name: 'newer.png',
                filePath: '/tmp/newer.png',
                type: MediaAssetType.image,
                fileSize: 0,
                createdAt: DateTime(2026, 1, 2),
              ),
            ],
          ),
        ),
      ),
    );

    final olderPosition = tester.getTopLeft(findAssetDrag('older'));
    final newerPosition = tester.getTopLeft(findAssetDrag('newer'));

    expect(olderPosition.dx, lessThan(newerPosition.dx));
  });

  testWidgets('shows default context menu without a builder', (tester) async {
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
    expect(find.text('删除'), findsOneWidget);

    await tester.tap(find.text('在文件夹中显示'));
    await tester.pumpAndSettle();

    expect(revealedAsset?.id, 'asset');
    expect(actions, [MediaAssetAction.revealInFolder]);

    await tester.tapAt(
      tester.getCenter(findAssetDrag('asset')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('删除'));
    await tester.pumpAndSettle();

    expect(deletedAsset?.id, 'asset');
  });

  testWidgets('customizes default action labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(
              layout: MediaAssetLayoutConfig(showToolbar: false),
              text: MediaAssetTextConfig(revealInFolderActionLabel: '定位文件'),
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

    expect(find.text('定位文件'), findsOneWidget);
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
    expect(find.text('删除'), findsNothing);
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
    expect(find.text('在文件夹中显示'), findsNothing);
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

  testWidgets(
    'selection badge is isolated from drag preview and hover overlay',
    (tester) async {
      MediaAsset? receivedAsset;
      final emittedSelections = <Set<String>>[];
      final previewActions = <MediaAssetAction>[];
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
                    onSelectionChanged: (ids) {
                      emittedSelections.add(ids);
                    },
                    onAssetAction: (action, asset) {
                      if (action == MediaAssetAction.preview) {
                        previewActions.add(action);
                      }
                    },
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

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(tester.getCenter(find.byIcon(Icons.add_rounded)));
      await tester.pump();

      expect(find.text('asset.png'), findsNothing);
      expect(find.text('0 B'), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byIcon(Icons.add_rounded)),
      );
      await tester.pump();

      expect(emittedSelections, [
        {'asset'},
      ]);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      await gesture.moveTo(
        tester.getCenter(find.byKey(const ValueKey('module-target'))),
      );
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(receivedAsset, isNull);
      expect(previewActions, isEmpty);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(emittedSelections.last, isEmpty);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    },
  );

  testWidgets('supports custom toolbar and selection badge builders', (
    tester,
  ) async {
    final emittedSelections = <Set<String>>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
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
            toolbarBuilder: (context, state) {
              return Text('自定义工具栏 ${state.selectedCount}/${state.assetCount}');
            },
            selectionBadgeBuilder: (context, asset, state) {
              return SizedBox(
                key: const ValueKey('custom-selection-badge'),
                width: 24,
                height: 24,
                child: Text(state.isBatchSelected ? 'Y' : 'N'),
              );
            },
            onSelectionChanged: (ids) {
              emittedSelections.add(ids);
            },
          ),
        ),
      ),
    );

    expect(find.text('自定义工具栏 0/1'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('custom-selection-badge')),
      findsOneWidget,
    );
    expect(find.text('N'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('custom-selection-badge')));
    await tester.pump();

    expect(emittedSelections, [
      {'asset'},
    ]);
    expect(find.text('自定义工具栏 1/1'), findsOneWidget);
    expect(find.text('Y'), findsOneWidget);
  });

  testWidgets('locks preview navigation while switching', (tester) async {
    final assets = [
      MediaAsset(
        id: 'asset-1',
        name: 'asset-1.png',
        filePath: '/tmp/asset-1.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 1),
      ),
      MediaAsset(
        id: 'asset-2',
        name: 'asset-2.png',
        filePath: '/tmp/asset-2.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 2),
      ),
      MediaAsset(
        id: 'asset-3',
        name: 'asset-3.png',
        filePath: '/tmp/asset-3.png',
        type: MediaAssetType.image,
        fileSize: 0,
        createdAt: DateTime(2026, 1, 3),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MediaAssetPreviewDialog(asset: assets.first, assets: assets),
      ),
    );

    final nextButton = find.byIcon(Icons.chevron_right_rounded);
    await tester.tap(nextButton);
    await tester.tap(nextButton);
    await tester.pump();

    expect(find.text('asset-2.png'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('asset-3.png'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));

    expect(find.byType(CircularProgressIndicator), findsNothing);
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
