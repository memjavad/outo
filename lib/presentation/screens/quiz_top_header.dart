import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:student_quiz_app/domain/entities/exam.dart';
import 'package:student_quiz_app/domain/entities/question.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class QuizTopHeader extends StatelessWidget {
  final Exam? exam;
  final ValueNotifier<int> tickNotifier;
  final int timeRemainingSeconds;
  final bool isReviewingEssay;
  final quill.QuillController? quillController;
  final List<QuizQuestion> questions;
  final Function(List<QuizQuestion>) onConfirmSubmit;
  final Function(List<QuizQuestion>) onConfirmWithdrawal;
  final VoidCallback onReviewEssay;

  const QuizTopHeader({
    super.key,
    required this.exam,
    required this.tickNotifier,
    required this.timeRemainingSeconds,
    required this.isReviewingEssay,
    this.quillController,
    required this.questions,
    required this.onConfirmSubmit,
    required this.onConfirmWithdrawal,
    required this.onReviewEssay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLowest,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(32),
                    onTap: () {
                      if (exam?.examType == 'essay') {
                        onConfirmWithdrawal(questions);
                      } else {
                        onConfirmSubmit(questions);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Timer Chip inside Header
                if (exam?.examType != 'campaign')
                  ValueListenableBuilder<int>(
                    valueListenable: tickNotifier,
                    builder: (context, _, child) {
                      final minutes = (timeRemainingSeconds ~/ 60)
                          .toString()
                          .padLeft(2, '0');
                      final seconds = (timeRemainingSeconds % 60)
                          .toString()
                          .padLeft(2, '0');
                      final isWarning = timeRemainingSeconds <= 60;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isWarning
                                  ? theme.colorScheme.errorContainer
                                  : theme.colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color:
                                  isWarning
                                      ? theme.colorScheme.error
                                      : theme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$minutes:$seconds',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color:
                                    isWarning
                                        ? theme.colorScheme.error
                                        : theme.primaryColor,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                if (exam?.examType != 'essay')
                  TextButton(
                    onPressed: () => onConfirmSubmit(questions),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      l10n.localeName == 'ar' ? 'إنهاء' : 'End Exam',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: theme.textTheme.bodyMedium?.fontFamily,
                      ),
                    ),
                  ),
                if (exam?.examType == 'essay' && !isReviewingEssay)
                  ElevatedButton(
                    onPressed: onReviewEssay,
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 0,
                      ),
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.localeName == 'ar' ? 'مراجعة' : 'REVIEW',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.remove_red_eye, size: 14),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (exam?.examType == 'essay' &&
              !isReviewingEssay &&
              quillController != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: theme.copyWith(
                          iconTheme: theme.iconTheme.copyWith(size: 20),
                        ),
                        child: quill.QuillSimpleToolbar(
                          controller: quillController!,
                          config: const quill.QuillSimpleToolbarConfig(
                            showFontFamily: false,
                            showFontSize: false,
                            showColorButton: false,
                            showBackgroundColorButton: false,
                            showSubscript: false,
                            showSuperscript: false,
                            showStrikeThrough: false,
                            showInlineCode: false,
                            showCodeBlock: false,
                            showSearchButton: false,
                            showLink: false,
                            showQuote: false,
                            showUndo: false,
                            showRedo: false,
                            showHeaderStyle: false,
                            showListCheck: false,
                            showClearFormat: false,
                            showIndent: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                    child: AnimatedBuilder(
                      animation: quillController!,
                      builder: (context, child) {
                        final text = quillController!.document.toPlainText();
                        final count =
                            text
                                .split(RegExp(r'\s+'))
                                .where((s) => s.isNotEmpty)
                                .length;
                        return Text(
                          '$count W',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
