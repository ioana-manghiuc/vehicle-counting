import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';
import '../localization/app_localizations.dart';
import '../widgets/app_bar.dart';
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            appBar: const AppBarWidget(titleKey: 'appTitle'),
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