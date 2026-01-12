import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final localizations = AppLocalizations.of(context);

    // Handle case where localization hasn't loaded yet
    if (localizations == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(localizations?.translate('appTitle') ?? 'Vehicle Counter'),
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
            ),
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await vm.pickVideo(context); 
                },
                child: Text(localizations?.translate('pickVideo') ?? 'Pick Video'),
              ),
            ),
          );
        },
      ),
    );
  }
}