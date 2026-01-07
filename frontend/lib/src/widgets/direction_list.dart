import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/directions_view_model.dart';

class DirectionList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DirectionsViewModel>();

    return ListView.builder(
      itemCount: vm.directions.length,
      itemBuilder: (_, index) {
        final d = vm.directions[index];
        return ListTile(
          title: Text(d.label),
          subtitle: Text('Points: ${d.points.length}'),
        );
      },
    );
  }
}