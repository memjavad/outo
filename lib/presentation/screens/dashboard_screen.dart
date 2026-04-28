import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:intl/intl.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../providers/quiz_service_facade.dart';
import '../../core/config/app_config.dart';
import '../../domain/entities/entities.dart';
import '../../core/localization/language_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/global_background.dart';
import '../../core/utils/platform_utils.dart';
import 'student_login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isOffline = false;
  List<Exam> _activeExams = [];
  Set<String> _completedExamIds = {};
  bool _isLoadingExams = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final service = Provider.of<QuizService>(context, listen: false);
    try {
      final exams = await service.fetchExams();
      Set<String> completed = {};

      if (service.isStudentLoggedIn) {
        final results = await service.fetchStudentResults();
        completed = results.map((r) => r.examId.toString()).toSet();
      }

      if (mounted) {
        setState(() {
          _activeExams = exams.where((e) => e.isActive).toList();
          _completedExamIds = completed;
          _isLoadingExams = false;
          _isOffline = service.isOffline;
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _isLoadingExams = false;
          _isOffline = true;
        });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final l10n = AppLocalizations.of(context)!;
    final quizService = Provider.of<QuizService>(context);

    if (!quizService.isStudentLoggedIn) {
      return const StudentLoginScreen();
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_ScoreTrackers(quizService: quizService)],
      ),
      body: GlobalBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 24.0,
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.04),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        [
                              _ProfileSummary(
                                theme: theme,
                                primaryColor: primaryColor,
                                l10n: l10n,
                                quizService: quizService,
                              ),
                              const SizedBox(height: 32),
                              _DashboardGrid(
                                theme: theme,
                                primaryColor: primaryColor,
                                l10n: l10n,
                              ),
                              const SizedBox(height: 32),
                            ]
                            .animate(interval: 50.ms)
                            .fade(duration: 500.ms, curve: Curves.easeOutQuad)
                            .slideY(begin: 0.05, end: 0),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreTrackers extends StatelessWidget {
  final QuizService quizService;

  const _ScoreTrackers({required this.quizService});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Star Tracker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6FF).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.star, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                '${quizService.currentStudent?.stars ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ).animate().shimmer(duration: 2.seconds, delay: 0.5.seconds),
        const SizedBox(width: 8),
        // Points Tracker
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFD700), Color(0xFFFDB931)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.coins, color: Colors.white, size: 14),
              const SizedBox(width: 6),
              Text(
                '${quizService.currentStudent?.points ?? 0}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
        const SizedBox(width: 16),
      ],
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  final ThemeData theme;
  final Color primaryColor;
  final AppLocalizations l10n;
  final QuizService quizService;

  const _ProfileSummary({
    required this.theme,
    required this.primaryColor,
    required this.l10n,
    required this.quizService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => context.push('/profile'),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(LucideIcons.user, color: primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.localeName == 'ar'
                            ? 'مرحباً بعودتك'
                            : 'Welcome Back',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\u202A${quizService.currentStudent?.name ?? "Student"}\u202C\u200F',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.readyForChallenge, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}

class _DashboardGrid extends StatelessWidget {
  final ThemeData theme;
  final Color primaryColor;
  final AppLocalizations l10n;

  const _DashboardGrid({
    required this.theme,
    required this.primaryColor,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _buildDashboardCard(
          context,
          title: l10n.localeName == 'ar'
              ? 'رحلة علم النفس'
              : 'Story of Psychology',
          icon: LucideIcons.map,
          color: Colors.purple,
          gradientColors: [Colors.purple.shade400, Colors.purple.shade800],
          onTap: () => context.push('/campaign_exams'),
        ),
        _buildDashboardCard(
          context,
          title: l10n.localeName == 'ar'
              ? 'الامتحانات الفردية'
              : 'Single Exams',
          icon: LucideIcons.fileText,
          color: primaryColor,
          gradientColors: [primaryColor.withValues(alpha: 0.8), primaryColor],
          onTap: () => context.push('/standard_exams'),
        ),
        _buildDashboardCard(
          context,
          title: l10n.essaysTab,
          icon: LucideIcons.penTool,
          color: Colors.indigo,
          gradientColors: [Colors.indigo.shade400, Colors.indigo.shade800],
          onTap: () => context.push('/essays_student'),
        ),
        _buildDashboardCard(
          context,
          title: l10n.myGrades,
          icon: LucideIcons.history,
          color: Colors.orange,
          gradientColors: [Colors.orange.shade400, Colors.deepOrange.shade800],
          onTap: () => context.push('/student_results'),
        ),
        _buildDashboardCard(
          context,
          title: l10n.leaderboard ?? 'Leaderboard',
          icon: LucideIcons.trophy,
          color: Colors.teal,
          gradientColors: [Colors.teal.shade400, Colors.teal.shade800],
          onTap: () => context.push('/leaderboard'),
        ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradientColors),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
