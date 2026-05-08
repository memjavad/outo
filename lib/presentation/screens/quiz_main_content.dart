import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:student_quiz_app/domain/entities/exam.dart';
import 'package:student_quiz_app/domain/entities/question.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class QuizMainContent extends StatelessWidget {
  final Exam? exam;
  final bool isReviewingEssay;
  final int currentQuestionIndex;
  final List<QuizQuestion> questions;
  final ValueNotifier<int> tickNotifier;
  final int questionTimeRemainingSeconds;
  final Function(int) getCampaignQuestionTime;
  final quill.QuillController? quillController;
  final Widget Function() buildPowerUpTray;
  final Map<int, dynamic> selectedAnswers;
  final List<List<int>> shuffledOptionIndices;
  final List<int> eliminatedOptions;
  final Function(int, List<QuizQuestion>) onAnswerQuestion;

  const QuizMainContent({
    super.key,
    required this.exam,
    required this.isReviewingEssay,
    required this.currentQuestionIndex,
    required this.questions,
    required this.tickNotifier,
    required this.questionTimeRemainingSeconds,
    required this.getCampaignQuestionTime,
    this.quillController,
    required this.buildPowerUpTray,
    required this.selectedAnswers,
    required this.shuffledOptionIndices,
    required this.eliminatedOptions,
    required this.onAnswerQuestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: (exam?.examType == 'essay' && !isReviewingEssay) ? 120 : 80,
          left: (exam?.examType == 'essay') ? 4 : 24,
          right: (exam?.examType == 'essay') ? 4 : 24,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (exam?.examType != 'essay') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localeName == 'ar' ? 'التقدم' : 'PROGRESS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: '${l10n.question} ${currentQuestionIndex + 1} ',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                      children: [
                        TextSpan(
                          text: l10n
                              .ofTotal(questions.length)
                              .replaceFirst('of ', 'of ')
                              .replaceFirst('من ', 'من '),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  progressIndicatorTheme: Theme.of(
                    context,
                  ).progressIndicatorTheme.copyWith(
                    color: Theme.of(context).primaryColor,
                    linearTrackColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    circularTrackColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(value: progress, minHeight: 6),
                ),
              ),
              const SizedBox(height: 48),
            ],

            // Asymmetric Question Layout
            if (exam?.examType == 'campaign')
              ValueListenableBuilder<int>(
                valueListenable: tickNotifier,
                builder: (context, _, child) {
                  int levelMatch =
                      int.tryParse(
                        RegExp(
                              r'\d+',
                            ).firstMatch(exam?.title ?? '')?.group(0) ??
                            '1',
                      ) ??
                      1;
                  int maxTime = getCampaignQuestionTime(levelMatch);
                  double timeProgress =
                      maxTime > 0 ? questionTimeRemainingSeconds / maxTime : 0;
                  bool isUrgent = questionTimeRemainingSeconds <= 5;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.localeName == 'ar'
                                  ? 'الوقت المتبقي'
                                  : 'TIME REMAINING',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                color:
                                    isUrgent
                                        ? Colors.redAccent
                                        : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '$questionTimeRemainingSeconds s',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isUrgent
                                        ? Colors.redAccent
                                        : theme.colorScheme.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            height: 8,
                            width: double.infinity,
                            alignment: AlignmentDirectional.centerStart,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: timeProgress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        isUrgent
                                            ? [
                                              Colors.redAccent,
                                              Colors.orangeAccent,
                                            ]
                                            : [
                                              Colors.amberAccent,
                                              Colors.orange,
                                            ],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isUrgent
                                              ? Colors.redAccent
                                              : Colors.orange)
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: -16,
                  top: 0,
                  child: Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    question.question,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            if (question.richText != null &&
                question.richText!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.04),
                      blurRadius: 30,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: MarkdownBody(
                  data: question.richText!,
                  selectable: false,
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
                    codeblockDecoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  question.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 40),

            if (question.questionType == 'short_answer' ||
                question.questionType == 'essay') ...[
              if (question.questionType != 'essay')
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                  child: Text(
                    l10n.localeName == 'ar' ? 'إجابتك' : 'YOUR RESPONSE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: question.questionType == 'essay' ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(
                    question.questionType == 'essay' ? 8 : 16,
                  ),
                  border:
                      question.questionType == 'essay'
                          ? Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.3,
                            ),
                            width: 1.0,
                          )
                          : null,
                  boxShadow: [
                    if (question.questionType == 'essay')
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      )
                    else
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.04,
                        ),
                        blurRadius: 40,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child:
                    question.questionType == 'essay' && quillController != null
                        ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 24,
                              ),
                              constraints: BoxConstraints(
                                minHeight:
                                    MediaQuery.of(context).size.height * 0.70,
                              ),
                              child: quill.QuillEditor.basic(
                                controller: quillController!,
                                config: quill.QuillEditorConfig(
                                  contextMenuBuilder: (
                                    context,
                                    rawEditorState,
                                  ) {
                                    return const SizedBox.shrink();
                                  },
                                  customStyles: quill.DefaultStyles(
                                    paragraph: quill.DefaultTextBlockStyle(
                                      TextStyle(
                                        fontSize: 16,
                                        height: 1.8,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                      const quill.HorizontalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      const quill.VerticalSpacing(0, 0),
                                      null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : TextField(
                          onChanged: (val) {
                            selectedAnswers[currentQuestionIndex] = val;
                          },
                          controller: TextEditingController(
                            text: selectedAnswers[currentQuestionIndex] ?? '',
                          ),
                          maxLines: null,
                          minLines: 3,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                          decoration: InputDecoration(
                            hintText:
                                l10n.localeName == 'ar'
                                    ? 'اكتب إجابتك هنا...'
                                    : 'Type your answer here...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(0.5),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(24),
                          ),
                        ),
              ),
              if (question.questionType != 'essay')
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant.withOpacity(
                          0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.localeName == 'ar'
                            ? 'سيتم حفظ إجابتك تلقائياً'
                            : 'Your answer is auto-saved',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              buildPowerUpTray(),
              ...List.generate(
                question.questionType == 'true_false'
                    ? 2
                    : question.options.length,
                (index) {
                  final originalIndex =
                      shuffledOptionIndices[currentQuestionIndex][index];
                  final isSelected =
                      selectedAnswers[currentQuestionIndex] == originalIndex;
                  final isEliminated = eliminatedOptions.contains(
                    originalIndex,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Semantics(
                      button: true,
                      label: question.options[originalIndex],
                      selected: isSelected,
                      child: IgnorePointer(
                        ignoring: isEliminated,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isEliminated ? 0.2 : 1.0,
                          child: ElevatedButton(
                            onPressed:
                                () =>
                                    onAnswerQuestion(originalIndex, questions),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side:
                                    isSelected
                                        ? BorderSide(
                                          color: Theme.of(context).primaryColor,
                                          width: 2,
                                        )
                                        : BorderSide.none,
                              ),
                              backgroundColor:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).primaryColor.withOpacity(0.05)
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerLowest,
                              foregroundColor:
                                  isSelected
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context).colorScheme.onSurface,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: Theme.of(context).primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                Text(
                                  question.options[originalIndex],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            const SizedBox(height: 48),
            // Ghost Icon Motif
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.menu_book,
                  size: 140,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 150),
          ], // <-- Closes children of Column
        ),
      ),
    );
  }
}
