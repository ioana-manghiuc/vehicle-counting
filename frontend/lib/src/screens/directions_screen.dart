import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/video_model.dart';
import '../providers/directions_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';
import '../widgets/draw_on_image.dart';
import '../widgets/directions_panel.dart';
import '../utils/backend_service.dart';

class DirectionsScreen extends StatelessWidget {
  final VideoModel video;

  const DirectionsScreen({super.key, required this.video});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: video.thumbnailUrl == null
          ? const Center(child: CircularProgressIndicator())
          : const _DirectionsScreenBody(),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final localizations = AppLocalizations.of(context);

    return AppBar(
      title: Text(localizations?.translate('drawDirections') ?? 'Draw Directions'),
      actions: [
        // Language toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ToggleButtons(
            isSelected: [
              languageProvider.locale.languageCode == 'en',
              languageProvider.locale.languageCode == 'ro',
            ],
            onPressed: (index) {
              languageProvider.setLanguage(index == 0 ? 'en' : 'ro');
            },
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('EN'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.0),
                child: Text('RO'),
              ),
            ],
          ),
        ),
        // Theme toggle
        IconButton(
          icon: Icon(
            themeProvider.isDark ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: themeProvider.toggleTheme,
          tooltip: themeProvider.isDark ? 'Light Mode' : 'Dark Mode',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _DirectionsScreenBody extends StatelessWidget {
  const _DirectionsScreenBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DirectionsProvider>();
    final localizations = AppLocalizations.of(context);
    // Get video from route arguments
    final video = ModalRoute.of(context)?.settings.arguments as VideoModel?;

    if (video == null) {
      return const Center(child: Text('Error: No video provided'));
    }

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: DrawOnImage(imageUrl: video.thumbnailUrl!),
        ),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              const Expanded(child: DirectionsPanel()),
              Padding(
                padding: const EdgeInsets.all(8),
                child: ElevatedButton(
                  onPressed: provider.canSend
                      ? () async {
                          await BackendService.sendDirections(
                            video.path,
                            provider.serializeDirections(),
                          );
                        }
                      : null,
                  child: Text(
                      localizations?.translate('sendToBackend') ??
                          'Send to Backend'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}