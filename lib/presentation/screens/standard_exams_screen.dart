import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../providers/quiz_service_facade.dart';
import '../widgets/global_background.dart';
import '../../domain/entities/entities.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class StandardExamsScreen extends StatefulWidget {
  const StandardExamsScreen({super.key});

  @override
  State<StandardExamsScreen> createState() => _StandardExamsScreenState();
}

class _StandardExamsScreenState extends State<StandardExamsScreen> {
  List<Exam> _standardExams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final service = Provider.of<QuizService>(context, listen: false);
    try {
      final exams = await service.fetchExams();
      if (mounted) {
        setState(() {
          _standardExams = exams.where((e) => e.isActive && e.examType == 'standard').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToInstructions(Exam exam) {
    context.push('/exam_instructions', extra: exam);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: GlobalBackground(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                   IconButton(
                     icon: Icon(Icons.arrow_back_ios_new, color: primaryColor),
                     onPressed: () => context.pop(),
                   ),
                   Expanded(
                     child: Text(
                       l10n.localeName == 'ar' ? 'الامتحانات الفردية' : 'Single Exams',
                       style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                       textAlign: TextAlign.center,
                     ),
                   ),
                   const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _standardExams.isEmpty
                      ? Center(child: Text(l10n.noExamsAvailable, style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                      : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _standardExams.length,
                  itemBuilder: (context, index) {
                    final exam = _standardExams[index];
                    
                    return Card(
                      elevation: 8,
                      shadowColor: Colors.black.withValues(alpha: 0.1),
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _navigateToInstructions(exam),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [primaryColor.withValues(alpha: 0.2), primaryColor.withValues(alpha: 0.05)]
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(LucideIcons.fileText, color: primaryColor, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exam.title, 
                                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                                    ),
                                    if (exam.description != null && exam.description!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          exam.description!, 
                                          maxLines: 2, 
                                          overflow: TextOverflow.ellipsis, 
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4)),
                                  ]
                                ),
                                child: Row(
                                  children: [
                                    Text(l10n.start, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                                    const SizedBox(width: 4),
                                    const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
