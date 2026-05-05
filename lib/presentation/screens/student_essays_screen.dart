import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../providers/quiz_service_facade.dart';
import '../widgets/global_background.dart';
import '../../domain/entities/entities.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class StudentEssaysScreen extends StatefulWidget {
  const StudentEssaysScreen({super.key});

  @override
  State<StudentEssaysScreen> createState() => _StudentEssaysScreenState();
}

class _StudentEssaysScreenState extends State<StudentEssaysScreen> {
  List<Exam> _essays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final service = Provider.of<QuizService>(context, listen: false);
    final exams = await service.fetchExams();
    if (mounted) {
      setState(() {
        _essays = exams.where((e) => e.examType == 'essay').toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = quizService.appSettings?.primaryColorHex != null
        ? Color(int.parse('FF${quizService.appSettings!.primaryColorHex.replaceAll("#", "")}', radix: 16))
        : Colors.indigo;
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
                     tooltip: l10n.goBack,
                     onPressed: () => context.pop(),
                   ),
                   Expanded(
                     child: Text(
                       l10n.essaysTab,
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
                  : _essays.isEmpty
                      ? Center(child: Text(l10n.noExamsAvailable, style: TextStyle(color: Colors.grey[600], fontSize: 16)))
                      : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _essays.length,
                  itemBuilder: (context, index) {
                    final exam = _essays[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200, width: 1),
                        boxShadow: [
                          if (!isDark) BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            context.push('/exam_instructions', extra: exam);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(LucideIcons.penTool, color: Colors.indigo),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      if (exam.description != null && exam.description!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          exam.description!,
                                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(LucideIcons.clock, size: 14, color: Colors.indigo.shade400),
                                          const SizedBox(width: 4),
                                          Text('${exam.examTimerMinutes} ${l10n.localeName == 'ar' ? 'دقيقة' : 'Min'}', style: TextStyle(color: Colors.indigo.shade400, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
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
