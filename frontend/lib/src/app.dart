import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'routing/route_handler.dart';
import 'settings/theme_provider.dart';
import 'settings/language_provider.dart';
import 'localization/app_localizations.dart';

class VehicleCounterApp extends StatelessWidget {
  const VehicleCounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, language, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: language.locale,
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