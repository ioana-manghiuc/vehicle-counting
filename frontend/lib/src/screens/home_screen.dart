import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/home_view_model.dart';
import '../routing/routes.dart';
import '../widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewModel(),
      child: Consumer<HomeViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Vehicle Counter')),
            body: Center(
              child: PrimaryButton(
                label: 'Upload Video',
                onPressed: () async {
                  await vm.pickVideo();
                  if (vm.video != null) {
                    Navigator.pushNamed(context, Routes.directions);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}