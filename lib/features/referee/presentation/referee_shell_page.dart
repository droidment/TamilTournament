import 'package:flutter/material.dart';

final class RefereeShellPage extends StatelessWidget {
  const RefereeShellPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Referee'),
        actions: [
          Chip(
            label: const Text('Referee'),
            backgroundColor: Colors.orange.shade50,
            side: BorderSide(color: Colors.orange.shade200),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Referee workspace',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tournament $tournamentId',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
