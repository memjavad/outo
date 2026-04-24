import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/global_background.dart';

class ReviewScreen extends StatelessWidget {
  final List<QuizQuestion> questions;
  final Map<int, dynamic> selectedAnswers;

  const ReviewScreen({
    super.key,
    required this.questions,
    required this.selectedAnswers,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GlobalBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).primaryColor,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text(
                      l10n.reviewAnswers,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24.0),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final question = questions[index];
                  final selectedOption = selectedAnswers[index];
                  return _ReviewQuestionCard(
                    question: question,
                    index: index,
                    selectedOption: selectedOption,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewQuestionCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;
  final dynamic selectedOption;

  const _ReviewQuestionCard({
    required this.question,
    required this.index,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 24.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l10n.question} ${index + 1}: ${question.question}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (question.richText != null &&
                question.richText!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Theme.of(context).brightness == Brightness.dark
                          ? Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          )
                          : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: MarkdownBody(
                  data: question.richText!,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    code: TextStyle(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ],
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  question.imageUrl!,
                  fit: BoxFit.cover,
                  height: 150,
                  width: double.infinity,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (question.questionType == 'short_answer') ...[
              _ShortAnswerReview(
                question: question,
                selectedOption: selectedOption,
              ),
            ] else ...[
              _MultipleChoiceReview(
                question: question,
                selectedOption: selectedOption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShortAnswerReview extends StatelessWidget {
  final QuizQuestion question;
  final dynamic selectedOption;

  const _ShortAnswerReview({
    required this.question,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final providedAnswer = selectedOption?.toString() ?? '';
    final correctAnswer = question.options[0];
    final isCorrect =
        providedAnswer.trim().toLowerCase() ==
        correctAnswer.trim().toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
            border: Border.all(color: isCorrect ? Colors.green : Colors.red),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.localeName == 'ar' ? 'إجابتك:' : 'Your Answer:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(providedAnswer.isEmpty ? '(No answer)' : providedAnswer),
            ],
          ),
        ),
        if (!isCorrect) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.localeName == 'ar'
                      ? 'الإجابة الصحيحة:'
                      : 'Correct Answer:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  correctAnswer,
                  style: const TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MultipleChoiceReview extends StatelessWidget {
  final QuizQuestion question;
  final dynamic selectedOption;

  const _MultipleChoiceReview({
    required this.question,
    required this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        question.questionType == 'true_false' ? 2 : question.options.length,
        (optIndex) {
          bool isSelected = selectedOption == optIndex;
          bool isCorrect = question.correctAnswerIndex == optIndex;

          Color bgColor = Colors.transparent;
          Color borderColor =
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0);
          IconData? icon;
          Color iconColor = Colors.transparent;

          if (isCorrect) {
            bgColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green;
            icon = Icons.check_circle;
            iconColor = Colors.green;
          } else if (isSelected && !isCorrect) {
            bgColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red;
            icon = Icons.cancel;
            iconColor = Colors.red;
          } else if (isSelected && isCorrect) {
            bgColor = Colors.green.withValues(alpha: 0.2);
            borderColor = Colors.green;
            icon = Icons.check_circle;
            iconColor = Colors.green;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon ?? Icons.circle_outlined, color: iconColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    question.options[optIndex],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          (isSelected || isCorrect)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
