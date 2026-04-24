import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:student_quiz_app/domain/entities/exam.dart';
import 'package:student_quiz_app/domain/entities/question.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class QuizBottomNavigation extends StatelessWidget {
  final Exam? exam;
  final bool isReviewingEssay;
  final int currentQuestionIndex;
  final List<QuizQuestion> questions;
  final VoidCallback onEditEssay;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuizBottomNavigation({
    super.key,
    required this.exam,
    required this.isReviewingEssay,
    required this.currentQuestionIndex,
    required this.questions,
    required this.onEditEssay,
    required this.onPrevious,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (exam?.examType == 'essay' && !isReviewingEssay) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              top: 16,
              left: 16,
              right: 16,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                  blurRadius: 40,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isReviewingEssay)
                  InkWell(
                    onTap: onEditEssay,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit,
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.8,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.localeName == 'ar'
                                ? 'تعديل الواجب'
                                : 'EDIT ESSAY',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (exam?.examType != 'essay')
                  Opacity(
                    opacity: currentQuestionIndex > 0 ? 1.0 : 0.4,
                    child: InkWell(
                      onTap: currentQuestionIndex > 0 ? onPrevious : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.localeName == 'ar' ? 'السابق' : 'PREVIOUS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: () {
                    if (currentQuestionIndex < questions.length - 1) {
                      onNext();
                    } else {
                      onSubmit();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 10,
                    shadowColor: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentQuestionIndex < questions.length - 1
                            ? (l10n.localeName == 'ar'
                                  ? 'التالي'
                                  : 'SAVE & NEXT')
                            : (isReviewingEssay
                                  ? (l10n.localeName == 'ar'
                                        ? 'تأكيد التسليم'
                                        : 'CONFIRM SUBMIT')
                                  : (l10n.localeName == 'ar'
                                        ? 'تسليم'
                                        : 'SUBMIT')),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
