import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'assessment_provider.dart';

class AssessmentResultScreen extends StatelessWidget {
  const AssessmentResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<AssessmentProvider>().result ?? {};
    final passed =
        result['passed'] == true ||
        result['status']?.toString().toLowerCase() == 'passed';
    return Scaffold(
      appBar: AppBar(title: const Text('Result')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  size: 72,
                  color: passed ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 14),
                Text(
                  passed ? 'Passed' : 'Result submitted',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Score: ${result['score'] ?? result['percentage'] ?? '-'}',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
