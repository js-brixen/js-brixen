import 'package:flutter/material.dart';

class ActionFab extends StatelessWidget {
  final VoidCallback onFilterPressed;

  const ActionFab({super.key, required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onFilterPressed,
      tooltip: 'Filter bookings',
      child: const Icon(Icons.filter_list),
    );
  }
}
