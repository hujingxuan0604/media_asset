import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:video_player/video_player.dart';

import '../models/media_asset_models.dart';
import '../theme/media_asset_theme.dart';

class VideoAssetPreview extends StatefulWidget {
  final MediaAsset asset;
  final Duration seekStep;
  final String missingMessage;
  final String loadFailureMessage;
  final bool showControls;

  const VideoAssetPreview({
    super.key,
    required this.asset,
    required this.seekStep,
    required this.missingMessage,
    required this.loadFailureMessage,
    this.showControls = true,
  });

  @override
  State<VideoAssetPreview> createState() => VideoAssetPreviewState();
}

class VideoAssetPreviewState extends State<VideoAssetPreview> {
  VideoPlayerController? _controller;
  bool _isLoading = false;
  bool _isSeeking = false;
  double _pendingSeekValue = 0;
  String? _errorText;
  int _loadRevision = 0;

  static bool _isFvpRegistered = false;

  @override
  void initState() {
    super.initState();
    _registerDesktopVideoPlayer();
    unawaited(_openVideo(widget.asset));
  }

  @override
  void didUpdateWidget(VideoAssetPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.asset.filePath != widget.asset.filePath) {
      unawaited(_openVideo(widget.asset));
    }
  }

  @override
  void dispose() {
    _loadRevision++;
    _controller?.dispose();
    super.dispose();
  }

  Future<void> togglePlayback() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
  }

  Future<void> seekBy(Duration offset) async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final duration = controller.value.duration;
    var target = controller.value.position + offset;
    if (target < Duration.zero) {
      target = Duration.zero;
    } else if (target > duration) {
      target = duration;
    }
    await controller.seekTo(target);
  }

  Future<void> _openVideo(MediaAsset asset) async {
    final revision = ++_loadRevision;
    final previous = _controller;
    setState(() {
      _controller = null;
      _isLoading = true;
      _errorText = null;
      _pendingSeekValue = 0;
      _isSeeking = false;
    });
    await previous?.dispose();

    final file = File(asset.filePath);
    if (!file.existsSync()) {
      if (!mounted || revision != _loadRevision) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorText = widget.missingMessage;
      });
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize().timeout(const Duration(seconds: 12));
      await controller.setLooping(false);
    } catch (_) {
      await controller.dispose();
      if (!mounted || revision != _loadRevision) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorText = widget.loadFailureMessage;
      });
      return;
    }

    if (!mounted || revision != _loadRevision) {
      await controller.dispose();
      return;
    }

    setState(() {
      _controller = controller;
      _isLoading = false;
    });
    unawaited(controller.play().catchError((_) {}));
  }

  Future<void> _seekTo(double milliseconds) async {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    await controller.seekTo(Duration(milliseconds: milliseconds.round()));
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _registerDesktopVideoPlayer() {
    if (_isFvpRegistered) {
      return;
    }
    _isFvpRegistered = true;
    fvp.registerWith(
      options: const {
        'platforms': ['windows', 'linux', 'macos'],
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MediaAssetTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.border(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: _errorText != null
                ? Center(
                    child: Text(
                      _errorText!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.86),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : _buildVideoSurface(),
          ),
          if (widget.showControls && _errorText == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildTimelineOverlay(context),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoSurface() {
    final controller = _controller;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (controller == null) {
      return const SizedBox.expand();
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.hasError) {
          return Center(
            child: Text(
              value.errorDescription ?? widget.loadFailureMessage,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.86),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
        if (!value.isInitialized) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final aspectRatio = value.aspectRatio <= 0 ? 16 / 9 : value.aspectRatio;
        return Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: VideoPlayer(controller),
          ),
        );
      },
    );
  }

  Widget _buildTimelineOverlay(BuildContext context) {
    final controller = _controller;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.68)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: controller == null
            ? _buildTimeline(Duration.zero, Duration.zero)
            : ValueListenableBuilder<VideoPlayerValue>(
                valueListenable: controller,
                builder: (context, value, child) {
                  return _buildTimeline(
                    value.position,
                    value.isInitialized ? value.duration : Duration.zero,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTimeline(Duration position, Duration duration) {
    final maxValue = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final sliderValue = _isSeeking
        ? _pendingSeekValue.clamp(0.0, maxValue)
        : position.inMilliseconds.clamp(0, maxValue.toInt()).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2.5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
          ),
          child: SizedBox(
            height: 22,
            child: Slider(
              value: sliderValue,
              max: maxValue,
              onChanged: duration.inMilliseconds <= 0
                  ? null
                  : (value) {
                      setState(() {
                        _isSeeking = true;
                        _pendingSeekValue = value;
                      });
                    },
              onChangeEnd: duration.inMilliseconds <= 0
                  ? null
                  : (value) async {
                      setState(() => _isSeeking = false);
                      await _seekTo(value);
                    },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _VideoTimeLabel(
              text:
                  '${_formatDuration(_isSeeking ? Duration(milliseconds: _pendingSeekValue.round()) : position)}/${duration == Duration.zero ? '读取中' : _formatDuration(duration)}',
            ),
            const SizedBox(width: 8),
            _VideoControlButton(
              icon: Icons.replay_5_rounded,
              tooltip: '后退 5 秒',
              onTap: () => seekBy(-widget.seekStep),
            ),
            const SizedBox(width: 5),
            _VideoControlButton(
              icon: _controller?.value.isPlaying == true
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              tooltip: _controller?.value.isPlaying == true ? '暂停' : '播放',
              onTap: togglePlayback,
            ),
            const SizedBox(width: 5),
            _VideoControlButton(
              icon: Icons.forward_5_rounded,
              tooltip: '前进 5 秒',
              onTap: () => seekBy(widget.seekStep),
            ),
          ],
        ),
      ],
    );
  }
}

class _VideoTimeLabel extends StatelessWidget {
  final String text;

  const _VideoTimeLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _VideoControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _VideoControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
