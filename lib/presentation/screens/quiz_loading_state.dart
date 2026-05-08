import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:student_quiz_app/domain/entities/exam.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class QuizLoadingState extends StatelessWidget {
  final Exam? exam;

  const QuizLoadingState({super.key, this.exam});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 80,
              color: theme.scaffoldBackgroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip:
                            MaterialLocalizations.of(
                              context,
                            ).closeButtonTooltip,
                        color: theme.primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        exam?.examType == 'essay'
                            ? (l10n.localeName == 'ar'
                                ? 'بوابة الواجبات'
                                : 'Essay Homework')
                            : 'Examination Portal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                          fontFamily: theme.textTheme.displayLarge?.fontFamily,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox.shrink(),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Skeletonizer(
                  enabled: true,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Loading question...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'This is a placeholder for the actual question text which is currently loading.',
                        ),
                        const SizedBox(height: 32),
                        ...List.generate(
                          4,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
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
