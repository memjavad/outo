import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/entities.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../widgets/global_background.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  List<Exam> _activeExams = [];

  List<Exam> get _essayExams => _activeExams.where((e) => e.examType == 'essay').toList();
  List<Exam> get _standardExams => _activeExams.where((e) => e.examType == 'standard').toList();

  Exam? _selectedEssayExam;
  Exam? _selectedStandardExam;

  List<LeaderboardEntry> _campaignLeaderboard = [];
  List<LeaderboardEntry> _essayLeaderboard = [];
  List<LeaderboardEntry> _standardLeaderboard = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final quizService = Provider.of<QuizService>(context, listen: false);
    setState(() => _isLoading = true);

    _activeExams = await quizService.fetchExams();
    if (_essayExams.isNotEmpty) _selectedEssayExam = _essayExams.first;
    if (_standardExams.isNotEmpty) _selectedStandardExam = _standardExams.first;

    await Future.wait([
      _fetchCampaignLeaderboard(quizService),
      if (_selectedEssayExam != null) _fetchEssayLeaderboard(_selectedEssayExam!.id, quizService),
      if (_selectedStandardExam != null) _fetchStandardLeaderboard(_selectedStandardExam!.id, quizService)
    ]);

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchCampaignLeaderboard(QuizService quizService) async {
    final lb = await quizService.fetchCampaignLeaderboard();
    if (mounted) setState(() => _campaignLeaderboard = lb);
  }

  Future<void> _fetchEssayLeaderboard(String examId, [QuizService? service]) async {
    final quizService = service ?? Provider.of<QuizService>(context, listen: false);
    if (service == null && mounted) setState(() => _isLoading = true);
    final lb = await quizService.fetchLeaderboard(examId);
    if (mounted) {
      setState(() {
        _essayLeaderboard = lb;
        if (service == null) _isLoading = false;
      });
    }
  }

  Future<void> _fetchStandardLeaderboard(String examId, [QuizService? service]) async {
    final quizService = service ?? Provider.of<QuizService>(context, listen: false);
    if (service == null && mounted) setState(() => _isLoading = true);
    final lb = await quizService.fetchLeaderboard(examId);
    if (mounted) {
      setState(() {
        _standardLeaderboard = lb;
        if (service == null) _isLoading = false;
      });
    }
  }

  Widget _buildMedal(int index) {
    if (index == 0) return const Icon(LucideIcons.medal, color: Color(0xFFFFD700), size: 32);
    if (index == 1) return const Icon(LucideIcons.medal, color: Color(0xFFC0C0C0), size: 32);
    if (index == 2) return const Icon(LucideIcons.medal, color: Color(0xFFCD7F32), size: 32);
    return Container(
      width: 32,
      alignment: Alignment.center,
      child: Text(
        '#${index + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> leaderboard, bool isCampaign) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.ghost, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              l10n.noScoresYet,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final entry = leaderboard[index];
        final isTop3 = index < 3;
        final medalColor = index == 0 ? const Color(0xFFFFD700) : (index == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32));

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isTop3 ? medalColor.withOpacity(0.05) : theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isTop3 ? [
              BoxShadow(
                color: medalColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              )
            ] : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: _buildMedal(index),
              title: Text(
                entry.studentName,
                style: TextStyle(
                  fontWeight: isTop3 ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isCampaign)
                     Text(
                      '${entry.scorePercentage.toInt()} XP', // Campaign mapping reuses scorePercentage as XP float
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                        fontSize: 16,
                      ),
                    )
                  else ...[
                    Text(
                      '${entry.scorePercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: entry.scorePercentage >= 50 ? Colors.green : Colors.red,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${(entry.timeTakenSeconds / 60).floor()}m ${entry.timeTakenSeconds % 60}s',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDropdownHeader(List<Exam> exams, Exam? selectedItem, ValueChanged<Exam?> onChanged) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.filter, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Exam>(
                isExpanded: true,
                value: selectedItem,
                hint: Text(l10n.selectExam),
                items: exams.map((exam) {
                  return DropdownMenuItem<Exam>(
                    value: exam,
                    child: Text(
                      exam.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: GlobalBackground(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: theme.primaryColor),
                      tooltip: l10n.goBack,
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        l10n.leaderboard,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: [
                Tab(icon: const Icon(LucideIcons.star), text: l10n.campaignTab),
                Tab(icon: const Icon(LucideIcons.fileText), text: l10n.essaysTab),
                Tab(icon: const Icon(LucideIcons.checkSquare), text: l10n.examsTab),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Campaign
                  Column(
                    children: [
                       Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(l10n.globalStoryPoints, style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                       ),
                       Expanded(child: _buildLeaderboardList(_campaignLeaderboard, true)),
                    ],
                  ),

                  // Tab 2: Essays
                  Column(
                    children: [
                       _buildDropdownHeader(_essayExams, _selectedEssayExam, (newExam) {
                          if (newExam != null && newExam.id != _selectedEssayExam?.id) {
                            setState(() => _selectedEssayExam = newExam);
                            _fetchEssayLeaderboard(newExam.id);
                          }
                       }),
                       Expanded(child: _buildLeaderboardList(_essayLeaderboard, false)),
                    ],
                  ),

                  // Tab 3: Standard Exams
                  Column(
                    children: [
                       _buildDropdownHeader(_standardExams, _selectedStandardExam, (newExam) {
                          if (newExam != null && newExam.id != _selectedStandardExam?.id) {
                            setState(() => _selectedStandardExam = newExam);
                            _fetchStandardLeaderboard(newExam.id);
                          }
                       }),
                       Expanded(child: _buildLeaderboardList(_standardLeaderboard, false)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
