import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/route_handler.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'localization/app_localizations.dart';
import 'providers/directions_provider.dart';

class VehicleCounterApp extends StatelessWidget {
  const VehicleCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => DirectionsProvider())
      ],
      child: Consumer2<LanguageProvider, ThemeProvider>(
        builder: (context, language, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: language.locale,
            theme: ThemeData(
              useMaterial3: true,
              fontFamily: GoogleFonts.phudu().fontFamily,
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              fontFamily: GoogleFonts.phudu().fontFamily,
            ),
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
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