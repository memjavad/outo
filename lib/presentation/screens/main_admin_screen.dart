import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_service_facade.dart';
import 'dashboard_screen.dart';
import 'exams_screen.dart';
import 'campaign_admin_screen.dart';
import 'essay_admin_screen.dart';
import 'live_monitoring_screen.dart';
import 'pending_students_screen.dart';
import 'analytics_admin_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class MainAdminScreen extends StatefulWidget {
  const MainAdminScreen({super.key});

  @override
  State<MainAdminScreen> createState() => _MainAdminScreenState();
}

class _MainAdminScreenState extends State<MainAdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(), // Question Bank
    const ExamsScreen(),     // Exam Manager
    const CampaignAdminScreen(), // NEW: Campaign Manager
    const EssayAdminScreen(), // NEW: Essay Manager
    const PendingStudentsScreen(), // Student Approvals
    const LiveMonitoringScreen(), // Live Sessions
    const AnalyticsAdminScreen(), // NEW: Analytics
  ];

  void _logout() async {
    await Provider.of<QuizService>(context, listen: false).logout();
    if (!mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    final titles = [
      l10n.localeName == 'ar' ? 'بنك الأسئلة' : 'Question Bank',
      l10n.localeName == 'ar' ? 'الامتحانات' : 'Exams',
      l10n.localeName == 'ar' ? 'القصة' : 'Campaigns',
      l10n.essaysTab,
      l10n.localeName == 'ar' ? 'طلبات الانضمام' : 'Approvals',
      l10n.localeName == 'ar' ? 'المراقبة المباشرة' : 'Live Monitor',
      l10n.analyticsTab ?? 'Analytics',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l10n.localeName == 'ar' ? 'تسجيل الخروج' : 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed, // Use fixed for 4+ items
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.library_books),
            label: l10n.localeName == 'ar' ? 'الأسئلة' : 'Questions',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment),
            label: l10n.localeName == 'ar' ? 'الامتحانات' : 'Exams',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n.localeName == 'ar' ? 'رحلة' : 'Story',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_document),
            label: l10n.essaysTab,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_add),
            label: l10n.localeName == 'ar' ? 'الطلبات' : 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.monitor_heart),
            label: l10n.localeName == 'ar' ? 'مراقبة' : 'Monitor',
          ),
          BottomNavigationBarItem(
            icon: const Icon(LucideIcons.barChart2),
            label: l10n.analyticsTab ?? 'Analytics',
          ),
        ],
      ),
    );
  }
}


