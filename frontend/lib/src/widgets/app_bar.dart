import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_flags/country_flags.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations.dart';

class AppBarWidget extends StatefulWidget implements PreferredSizeWidget {
  final String titleKey;

  const AppBarWidget({super.key, required this.titleKey});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppBarWidget> createState() => _AppBarWidgetState();
}

class _AppBarWidgetState extends State<AppBarWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = context.watch<LanguageProvider>();
    final localizations = AppLocalizations.of(context);

    return AppBar(
      title: Text(localizations?.translate(widget.titleKey) ?? widget.titleKey),
      actions: [
        // Language dropdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: DropdownButton<String>(
            focusNode: _focusNode,
            value: languageProvider.locale.languageCode,
            items: [
              DropdownMenuItem(
                value: 'en',
                child: Row(
                  children: [
                    CountryFlag.fromCountryCode(
                      'GB',
                      theme: const ImageTheme(
                        shape: RoundedRectangle(2),
                        width: 30,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('EN'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: 'ro',
                child: Row(
                  children: [
                    CountryFlag.fromCountryCode(
                      'RO',
                      theme: const ImageTheme(
                        shape: RoundedRectangle(2),
                        width: 30,
                        height: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('RO'),
                  ],
                ),
              ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                languageProvider.setLanguage(value);
                _focusNode.unfocus(); // Close dropdown
              }
            },
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
