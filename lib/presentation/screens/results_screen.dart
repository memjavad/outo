import 'package:flutter/material.dart';
import '../../domain/entities/entities.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_service_facade.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/platform_utils.dart';

class ResultsScreen extends StatefulWidget {
  final QuizResult result;
  final List<QuizQuestion> questions;
  final Map<int, dynamic> selectedAnswers;
  final bool allowReview;
  final bool isEssay;
  final Exam? exam;

  const ResultsScreen({
    super.key, 
    required this.result,
    required this.questions,
    required this.selectedAnswers,
    required this.allowReview,
    this.isEssay = false,
    this.exam,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (widget.result.pointsEarned > 0) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEssayState = widget.isEssay || (widget.questions.isNotEmpty && widget.questions.first.questionType == 'essay');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Decorative Asymmetric Floating Shapes
          Positioned(
            top: -MediaQuery.sizeOf(context).height * 0.1,
            left: -MediaQuery.sizeOf(context).width * 0.1,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.sizeOf(context).height * 0.05,
            right: -MediaQuery.sizeOf(context).width * 0.05,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primaryContainer.withOpacity(0.04),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isEssayState 
                        ? (l10n.localeName == 'ar' ? 'تم تسليم الواجب!' : 'Essay Submitted!') 
                        : (widget.exam?.examType == 'campaign' 
                            ? (l10n.localeName == 'ar' ? 'تم إنهاء المستوى!' : 'Level Completed!') 
                            : l10n.quizCompleted),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.2),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        if (isEssayState) ...[
                          Icon(LucideIcons.clock, size: 60, color: Colors.orange),
                          const SizedBox(height: 16),
                          Text(
                            l10n.localeName == 'ar' ? 'بانتظار التقييم' : 'Pending Review',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 140,
                            child: Text(
                              l10n.localeName == 'ar' ? 'سيتم إشعارك حين يقوم الأستاذ بتقييم واجبك' : 'You will be notified once graded.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ] else if (widget.result.examType == 'campaign') ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(3, (starIndex) {
                              bool isEarned = starIndex < widget.result.earnedStars;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Icon(
                                  isEarned ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: isEarned ? Colors.amberAccent : Colors.grey.shade600,
                                  size: 48,
                                  shadows: [
                                    if (isEarned)
                                      const Shadow(color: Colors.orange, blurRadius: 12)
                                  ],
                                ),
                              ).animate(delay: (300 + starIndex * 200).ms).scaleXY(begin: 0, end: 1.0, curve: Curves.elasticOut);
                            }),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.localeName == 'ar' ? '${widget.result.campaignScore} نقطة' : '${widget.result.campaignScore} Pts',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                              shadows: [const Shadow(color: Colors.blueAccent, blurRadius: 8)],
                            ),
                          ).animate(delay: 1000.ms).fadeIn().slideY(begin: 0.2),
                        ] else ...[
                          Text(
                            widget.result.grade,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                              height: 1,
                            ),
                          ),
                          Text(
                            '${widget.result.scorePercentage.toInt()}%',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ).animate().scale(delay: 200.ms, curve: Curves.easeOutBack),
                  const SizedBox(height: 40),
                  
                  // Stats Container
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.04),
                          blurRadius: 30,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        if (widget.result.pointsEarned > 0) ...[
                          _buildInfoRow(
                            context,
                            l10n.localeName == 'ar' ? 'نقاط الخبرة:' : 'XP Earned',
                            '+ ${widget.result.pointsEarned}',
                            isPremium: true
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Divider(color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                          ),
                        ],
                        if (!isEssayState) ...[
                          _buildInfoRow(
                            context,
                            l10n.correctAnswers,
                            '${widget.result.correctAnswers}/${widget.result.totalQuestions}',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Divider(color: colorScheme.onSurfaceVariant.withOpacity(0.1)),
                          ),
                        ],
                        _buildInfoRow(
                          context,
                          l10n.timeTaken,
                          '${widget.result.timeTaken.inMinutes}:${(widget.result.timeTaken.inSeconds % 60).toString().padLeft(2, '0')}',
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                  
                  const SizedBox(height: 40),
                  if (widget.allowReview && !isEssayState)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0, left: 24, right: 24),
                      child: Container(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            context.push('/review', extra: {
                               'questions': widget.questions,
                               'selectedAnswers': widget.selectedAnswers,
                            });
                          },
                          child: Text(
                            l10n.localeName == 'ar' ? 'مراجعة الإجابات' : 'Review Answers',
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  if (widget.exam?.examType == 'campaign')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (widget.exam != null) {
                                  context.pushReplacement('/quiz', extra: {
                                    'exam': widget.exam,
                                    'studentName': widget.result.studentName,
                                    'entryGpsLocation': widget.result.gpsLocation,
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                foregroundColor: colorScheme.onSurface,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                elevation: 0,
                              ),
                              child: Text(l10n.localeName == 'ar' ? 'إعادة' : 'Redo Level', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.2),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    colorScheme.primary,
                                    colorScheme.primaryContainer,
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () => context.go('/campaign_exams'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: Text(l10n.localeName == 'ar' ? 'المستوى التالي' : 'Next Level', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 500.ms)
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.2),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary,
                              colorScheme.primaryContainer,
                            ],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(l10n.backToStart),
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms),
                ],
              ),
            ),
          ),
          if (widget.result.pointsEarned > 0)
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isPremium = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isPremium ? const Color(0xFFD97706) : colorScheme.onSurfaceVariant,
              fontWeight: isPremium ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: isPremium ? const Color(0xFFD97706) : colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}



