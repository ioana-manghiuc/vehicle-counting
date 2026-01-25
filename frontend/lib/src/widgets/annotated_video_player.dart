import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../localization/app_localizations.dart';

class AnnotatedVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const AnnotatedVideoPlayer({super.key, required this.videoUrl});

  @override
  State<AnnotatedVideoPlayer> createState() => _AnnotatedVideoPlayerState();
}

class _AnnotatedVideoPlayerState extends State<AnnotatedVideoPlayer> {
  late VideoPlayerController _controller;
  OverlayEntry? _fullscreenEntry;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    const backendUrl = 'http://127.0.0.1:8000';
    final fullUrl = '$backendUrl${widget.videoUrl}';

    _controller = VideoPlayerController.networkUrl(
      Uri.parse(fullUrl),
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: true,
      ),
    )
      ..setLooping(false)
      ..initialize().then((_) {
        if (mounted) setState(() {});
      }).catchError((error) {
        debugPrint('Error initializing video: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)?.translate('loadingVideo') ?? 'Loading video...',
            ),
          ],
        ),
      );
    }

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, child) {
        final bool isEnded = value.isInitialized &&
            value.duration > Duration.zero &&
            value.position >= value.duration - const Duration(milliseconds: 100);

        if (isEnded && !value.isPlaying) {
          // Ensure player is paused at end to avoid further network requests
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await _controller.pause();
            } catch (_) {}
          });
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () {
                if (value.isPlaying) {
                  _controller.pause();
                } else {
                  if (isEnded) {
                    _controller.seekTo(Duration.zero);
                  }
                  _controller.play();
                }
              },
              child: Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                tooltip: 'Fullscreen',
                onPressed: _showFullscreen,
                icon: const Icon(Icons.fullscreen, color: Colors.white),
              ),
            ),
            if (!value.isPlaying)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            if (value.isPlaying)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: Theme.of(context).colorScheme.primary,
                    bufferedColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundColor: Colors.grey,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullscreen() {
    if (_fullscreenEntry != null) return;
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _fullscreenEntry = OverlayEntry(
      builder: (ctx) {
        return Material(
          color: Colors.black.withOpacity(0.92),
          child: SafeArea(
            child: ValueListenableBuilder<VideoPlayerValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final bool isEnded = value.isInitialized &&
                    value.duration > Duration.zero &&
                    value.position >= value.duration - const Duration(milliseconds: 100);

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (value.isPlaying) {
                          _controller.pause();
                        } else {
                          if (isEnded) {
                            _controller.seekTo(Duration.zero);
                          }
                          _controller.play();
                        }
                      },
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: value.isInitialized ? value.aspectRatio : (16 / 9),
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    // Exit fullscreen control
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton(
                            tooltip: 'Exit fullscreen',
                            onPressed: _hideFullscreen,
                            icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Theme.of(context).colorScheme.primary,
                          bufferedColor: Theme.of(context).colorScheme.primaryContainer,
                          backgroundColor: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );

    overlay.insert(_fullscreenEntry!);
  }

  void _hideFullscreen() {
    _fullscreenEntry?.remove();
    _fullscreenEntry = null;
  }
}
