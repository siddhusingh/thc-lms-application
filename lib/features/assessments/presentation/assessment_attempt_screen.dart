import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../models/assessment_model.dart';
import 'assessment_provider.dart';

class AssessmentAttemptScreen extends StatefulWidget {
  const AssessmentAttemptScreen({required this.assessmentId, super.key});

  final String assessmentId;

  @override
  State<AssessmentAttemptScreen> createState() =>
      _AssessmentAttemptScreenState();
}

class _AssessmentAttemptScreenState extends State<AssessmentAttemptScreen> {
  final Map<String, String> _answers = {};
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final provider = context.read<AssessmentProvider>();
    final ok = await provider.start(widget.assessmentId);
    if (!mounted || !ok) return;
    _remaining = provider.attempt?.durationSeconds ?? 0;
    if (_remaining > 0) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_remaining <= 1) {
          _timer?.cancel();
          _submit();
        } else {
          setState(() => _remaining--);
        }
      });
    }
  }

  Future<void> _submit() async {
    final ok = await context.read<AssessmentProvider>().submit(_answers);
    if (!mounted || !ok) return;
    context.go('/assessment-result');
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AssessmentProvider>();
    final attempt = provider.attempt;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment'),
        actions: [
          if (_remaining > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${(_remaining ~/ 60).toString().padLeft(2, '0')}:${(_remaining % 60).toString().padLeft(2, '0')}',
                ),
              ),
            ),
        ],
      ),
      body: provider.loading && attempt == null
          ? const Center(child: CircularProgressIndicator())
          : attempt == null
          ? Center(child: Text(provider.error ?? 'Unable to start assessment.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...attempt.questions.map(
                  (question) => _QuestionCard(
                    question: question,
                    selected: _answers[question.id],
                    onChanged: (value) =>
                        setState(() => _answers[question.id] = value),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: provider.loading ? null : _submit,
                  child: provider.loading
                      ? const CircularProgressIndicator()
                      : const Text('Submit assessment'),
                ),
              ],
            ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.selected,
    required this.onChanged,
  });

  final QuestionModel question;
  final String? selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question.question,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ...question.options.map(
              (option) => InkWell(
                onTap: () => onChanged(option.id),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        selected == option.id
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: selected == option.id
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(option.text)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
