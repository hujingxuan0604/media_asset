import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_asset/media_asset.dart';

void main() {
  testWidgets('renders an empty media asset library', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            assets: [],
            config: MediaAssetLibraryConfig(showToolbar: false),
          ),
        ),
      ),
    );

    expect(find.text('拖入图片或视频'), findsOneWidget);
    expect(find.byIcon(Icons.perm_media_outlined), findsOneWidget);
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
            config: const MediaAssetLibraryConfig(showToolbar: false),
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

    final newerPosition = tester.getTopLeft(find.text('newer.png'));
    final olderPosition = tester.getTopLeft(find.text('older.png'));

    expect(newerPosition.dx, lessThan(olderPosition.dx));
  });

  testWidgets('does not show a default context menu without a builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(showToolbar: false),
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
      tester.getCenter(find.text('asset.png')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('预览'), findsNothing);
    expect(find.text('选择'), findsNothing);
  });

  testWidgets('shows custom context menu from builder and wires actions', (
    tester,
  ) async {
    MediaAsset? deletedAsset;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaAssetLibrary(
            config: const MediaAssetLibraryConfig(showToolbar: false),
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
      tester.getCenter(find.text('asset.png')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();

    expect(find.text('自定义删除'), findsOneWidget);

    await tester.tap(find.text('自定义删除'));
    await tester.pumpAndSettle();

    expect(deletedAsset?.id, 'asset');
    expect(find.text('自定义删除'), findsNothing);
  });
}
