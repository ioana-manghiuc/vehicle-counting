// lib/src/routing/route_handler.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/directions_screen.dart';
import '../screens/results_screen.dart';
import '../models/video_model.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/directions':
        if (settings.arguments is VideoModel) {
          final video = settings.arguments as VideoModel;
          return MaterialPageRoute(
            builder: (_) => DirectionsScreen(video: video),
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(
                child: Text(
                  'Error: VideoModel is required for DirectionsScreen',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          );
        }

      case '/results':
        return MaterialPageRoute(builder: (_) => const ResultsScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'No route defined for this path',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        );
    }
  }
}
