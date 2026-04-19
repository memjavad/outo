import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/entities/analytics_model.dart';
import '../../domain/entities/exam.dart';
import '../../data/sources/remote/api_exams.dart';

class AnalyticsAdminScreen extends StatefulWidget {
  const AnalyticsAdminScreen({super.key});

  @override
  State<AnalyticsAdminScreen> createState() => _AnalyticsAdminScreenState();
}

class _AnalyticsAdminScreenState extends State<AnalyticsAdminScreen> {
  final AnalyticsRepository _analyticsRepo = AnalyticsRepository();
  List<Exam> _exams = [];
  Exam? _selectedExam;
  
  bool _isLoading = true;
  ExamKPI? _kpis;
  List<DistractorData>? _distractors;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      final exams = await ApiExams().fetchExams();
      if (mounted) {
        setState(() {
          _exams = exams.where((e) => e.examType != 'essay').toList(); // Filter out essays for distractor analytics
          if (_exams.isNotEmpty) {
            _selectedExam = _exams.first;
            _fetchAnalytics();
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchAnalytics() async {
    if (_selectedExam == null) return;
    setState(() => _isLoading = true);
    
    try {
      final kpis = await _analyticsRepo.fetchExamKPIs(_selectedExam!.id!);
      final distractors = await _analyticsRepo.fetchDistractorAnalysis(_selectedExam!.id!);
      
      if (mounted) {
        setState(() {
          _kpis = kpis;
          _distractors = distractors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.analyticsTab ?? 'Analytics', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _exams.isEmpty 
          ? Center(child: Text(l10n.noAvailableExams ?? 'No exams available for analytics.'))
          : RefreshIndicator(
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Exam Selector Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[900] : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Exam>(
                          isExpanded: true,
                          value: _selectedExam,
                          icon: const Icon(LucideIcons.chevronDown),
                          items: _exams.map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          )).toList(),
                          onChanged: (exam) {
                            if (exam != null && exam.id != _selectedExam?.id) {
                              setState(() {
                                _selectedExam = exam;
                              });
                              _fetchAnalytics();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // KPIs Row
                    if (_kpis != null)
                      Row(
                        children: [
                          Expanded(child: _buildKPICard(l10n.totalStudents ?? 'Total Students', _kpis!.totalStudents.toString(), LucideIcons.users, Colors.blue)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildKPICard(l10n.averageScore ?? 'Avg Score', '${_kpis!.averageScore}%', LucideIcons.target, Colors.purple)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildKPICard(l10n.passRate ?? 'Pass Rate', '${_kpis!.passRate}%', LucideIcons.checkCircle, _kpis!.passRate >= 50 ? Colors.green : Colors.red)),
                        ],
                      ),
                    
                    const SizedBox(height: 32),
                    Text(l10n.distractorAnalysis ?? 'Distractor Analysis', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Distractors List
                    if (_distractors != null && _distractors!.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _distractors!.length,
                        itemBuilder: (context, index) {
                          final data = _distractors![index];
                          return _buildDistractorCard(data, isDark, theme);
                        },
                      )
                    else 
                      Container(
                        padding: const EdgeInsets.all(32),
                        alignment: Alignment.center,
                        child: Text("No analytic data yet for this exam.", style: TextStyle(color: theme.hintColor)),
                      ),
                  ],
                ),
              ),
          ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
        ]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildDistractorCard(DistractorData data, bool isDark, ThemeData theme) {
    // Generate vibrant colors for options
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(LucideIcons.helpCircle, color: theme.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(data.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                height: 120,
                width: 120,
                child: data.totalAnswers == 0 
                ? const Center(child: Text("No Data"))
                : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30,
                    sections: data.distractors.map((dist) {
                      int cIdx = (dist.optionIndex >= 0 ? dist.optionIndex : 4) % colors.length;
                      return PieChartSectionData(
                        color: colors[cIdx],
                        value: dist.percentage,
                        title: '${dist.percentage.toInt()}%',
                        radius: 30,
                        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: data.distractors.map((dist) {
                     int cIdx = (dist.optionIndex >= 0 ? dist.optionIndex : 4) % colors.length;
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4),
                       child: Row(
                         children: [
                           Container(width: 12, height: 12, decoration: BoxDecoration(color: colors[cIdx], shape: BoxShape.circle)),
                           const SizedBox(width: 8),
                           Text(dist.optionIndex == -1 ? "Skipped" : "Option ${String.fromCharCode(65 + dist.optionIndex)}", style: const TextStyle(fontWeight: FontWeight.w500)),
                         ],
                       ),
                     );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
