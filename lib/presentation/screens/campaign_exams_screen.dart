import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../providers/quiz_service_facade.dart';
import '../widgets/global_background.dart';
import '../widgets/campaign_level_map.dart';
import '../../domain/entities/entities.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CampaignExamsScreen extends StatefulWidget {
  const CampaignExamsScreen({super.key});

  @override
  State<CampaignExamsScreen> createState() => _CampaignExamsScreenState();
}

class _CampaignExamsScreenState extends State<CampaignExamsScreen> {
  List<Exam> _campaignExams = [];
  Map<String, double> _examScores = {};
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
      Map<String, double> scores = {};
      
      if (service.isStudentLoggedIn) {
        await service.refreshStudentProfile();
        final results = await service.fetchStudentResults();
        for (var r in results) {
          final id = r.examId.toString();
          if (!scores.containsKey(id) || r.scorePercentage > scores[id]!) {
            scores[id] = r.scorePercentage;
          }
        }
      }
      
      if (mounted) {
        setState(() {
          final campaignList = exams.where((e) => e.isActive && e.examType == 'campaign').toList();
          // Sort ascending by ID to guarantee chronological progression (Level 1 at bottom index 0)
          campaignList.sort((a, b) => (int.tryParse(a.id) ?? 0).compareTo(int.tryParse(b.id) ?? 0));
          
          _campaignExams = campaignList;
          _examScores = scores;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToInstructions(Exam exam) async {
    await context.push('/exam_instructions', extra: exam);
    _loadData();
  }

  void _showInstructionsSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 24),
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(10)),
            ),
            Text(
              l10n.campaignRules,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildRuleCard(
                    icon: LucideIcons.zap,
                    color: Colors.amberAccent,
                    title: l10n.speedAccuracy,
                    desc: l10n.speedAccuracyDesc,
                  ),
                  _buildRuleCard(
                    icon: LucideIcons.flame,
                    color: Colors.orangeAccent,
                    title: l10n.comboMultipliers,
                    desc: l10n.comboMultipliersDesc,
                  ),
                  _buildRuleCard(
                    icon: LucideIcons.shieldCheck,
                    color: Colors.greenAccent,
                    title: l10n.trainingLevels,
                    desc: l10n.trainingLevelsDesc,
                  ),
                  _buildRuleCard(
                    icon: LucideIcons.skull,
                    color: Colors.redAccent,
                    title: l10n.hardcoreLevels,
                    desc: l10n.hardcoreLevelsDesc,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.iUnderstand, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard({required IconData icon, required Color color, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 6),
                Text(desc, style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, // Pure black fallback for cosmic theme
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: l10n.goBack,
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.cyanAccent), // Neon theme
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n.localeName == 'ar' ? 'رحلة علم النفس' : 'Story of Psychology',
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: l10n.info,
            icon: const Icon(LucideIcons.info, color: Colors.white70),
            onPressed: () => _showInstructionsSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : _campaignExams.isEmpty
                  ? Center(child: Text(l10n.noExamsAvailable, style: const TextStyle(color: Colors.white70, fontSize: 16)))
                  : CampaignLevelMap(
                      exams: _campaignExams,
                      examScores: _examScores,
                      onNodeTap: _navigateToInstructions,
                    ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Points Tracker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.coins, color: Colors.amberAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${Provider.of<QuizService>(context).currentStudent?.points ?? 0}',
                            style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Star Tracker
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.star, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${Provider.of<QuizService>(context).currentStudent?.stars ?? 0}',
                            style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Store Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: l10n.store,
                        icon: const Icon(LucideIcons.shoppingCart, color: Colors.amberAccent),
                        onPressed: () => context.push('/store'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
