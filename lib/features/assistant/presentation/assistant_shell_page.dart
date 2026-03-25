import 'package:flutter/material.dart';

final class AssistantShellPage extends StatelessWidget {
  const AssistantShellPage({required this.tournamentId, super.key});

  final String tournamentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant'),
        actions: [
          Chip(
            label: const Text('Assistant'),
            backgroundColor: Colors.teal.shade50,
            side: BorderSide(color: Colors.teal.shade200),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_ind_outlined,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Assistant workspace',
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
