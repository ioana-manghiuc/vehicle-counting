import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/directions_screen.dart';
import '../screens/results_screen.dart';
import '../screens/about_screen.dart';
import '../screens/model_info_screen.dart';
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
        }

        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text(
                'Error: VideoModel required for DirectionsScreen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        );

      case '/results':
        return MaterialPageRoute(builder: (_) => const ResultsScreen());

      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      case '/model-info':
        return MaterialPageRoute(builder: (_) => const ModelInfoScreen());

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
