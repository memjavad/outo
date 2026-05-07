import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/entities.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/global_background.dart';

class StudentResultsScreen extends StatefulWidget {
  const StudentResultsScreen({super.key});

  @override
  State<StudentResultsScreen> createState() => _StudentResultsScreenState();
}

class _StudentResultsScreenState extends State<StudentResultsScreen> {
  List<QuizResult> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    final service = Provider.of<QuizService>(context, listen: false);
    final results = await service.fetchStudentResults();
    if (mounted) {
      setState(() {
        _results = results;
        _isLoading = false;
      });
    }
  }

  Widget _buildResultsList(List<QuizResult> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_edu, size: 80, color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noResultsFound,
              style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadResults,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final result = list[index];
          final date = result.createdAt != null
              ? DateFormat('MMM d, y • HH:mm').format(result.createdAt!)
              : AppLocalizations.of(context)!.unknownDate;
          
          final isPending = result.examType == 'essay' && !result.isGraded;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                  blurRadius: 30,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isPending 
                    ? Colors.orange.withValues(alpha: 0.1) 
                    : (result.grade == 'F' ? Colors.red : Colors.green).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isPending 
                    ? const Icon(Icons.access_time, color: Colors.orange)
                    : Text(
                      result.grade,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: result.grade == 'F' ? Colors.red : Colors.green,
                      ),
                    ),
                ),
              ),
              title: Text(
                result.examTitle ?? AppLocalizations.of(context)!.generalQuiz,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(date, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 13)),
                  const SizedBox(height: 4),
                  if (isPending)
                    Text(
                      AppLocalizations.of(context)!.localeName == 'ar' ? 'بانتظار التقييم' : 'Pending Grade',
                      style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold),
                    )
                  else if (result.examType == 'essay' && result.isGraded)
                    Text(
                      AppLocalizations.of(context)!.localeName == 'ar' ? 'تم التقييم' : 'Graded',
                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                    )
                  else
                    Text(
                      AppLocalizations.of(context)!.questionsCount(result.correctAnswers, result.totalQuestions),
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (result.examType == 'essay' && result.isGraded && result.teacherFeedback != null && result.teacherFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border(left: BorderSide(color: Theme.of(context).colorScheme.primary, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.comment_outlined, size: 14, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!.localeName == 'ar' ? 'ملاحظات التقييم' : 'Evaluation Feedback',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.teacherFeedback!,
                            style: TextStyle(
                              fontSize: 13, 
                              height: 1.5,
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9)
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isPending)
                    const Text('--%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey))
                  else
                    Text(
                      '${result.scorePercentage.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const Icon(Icons.chevron_right, size: 16),
                ],
              ),
              onTap: () {
                // Navigation to detailed review could be added here
              },
            ),
            ),
          ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOut);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final examsList = _results.where((r) => r.examType != 'essay').toList();
    final essaysList = _results.where((r) => r.examType == 'essay').toList();
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: GlobalBackground(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16.0, 
                  left: 16.0, 
                  right: 16.0, 
                  bottom: 8.0
                ),
                child: Row(
                  children: [
                     IconButton(
                       tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                       icon: Icon(Icons.arrow_back_ios_new, color: Theme.of(context).primaryColor),
                       onPressed: () => context.pop(),
                     ),
                     Expanded(
                       child: Text(
                         l10n.myQuizHistory,
                         style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                         textAlign: TextAlign.center,
                       ),
                     ),
                     const SizedBox(width: 48), // balance chevron
                  ],
                ),
              ),
              
              // Tabs Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(context).textTheme.bodyMedium?.color,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(text: l10n.localeName == 'ar' ? 'الاختبارات' : 'Exams'),
                    Tab(text: l10n.essaysTab),
                  ],
                ),
              ),

              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          _buildResultsList(examsList),
                          _buildResultsList(essaysList),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
