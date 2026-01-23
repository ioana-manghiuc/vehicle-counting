import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routing/route_handler.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'localization/app_localizations.dart';
import 'view_models/directions_view_model.dart';
import 'view_models/results_view_model.dart';
import 'theme/app_theme.dart';
class VCount extends StatelessWidget {
  const VCount({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => DirectionsViewModel()),
        ChangeNotifierProvider(create: (context) => ResultsViewModel()),
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, language, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: language.locale,
            theme: lightMode,
            darkTheme: darkMode,
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/start',
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            onGenerateRoute: AppRouter.generateRoute,
          );
        },
      ),
    );
  }
}