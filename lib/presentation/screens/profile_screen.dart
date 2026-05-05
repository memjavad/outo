import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/entities.dart';
import '../providers/quiz_service_facade.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/localization/language_provider.dart';
import 'package:intl/intl.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../widgets/global_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  Future<List<QuizResult>>? _resultsFuture;

  @override
  void initState() {
    super.initState();
    final quizService = Provider.of<QuizService>(context, listen: false);
    final student = quizService.currentStudent;
    if (student != null) {
      _nameController.text = student.name;
      _bioController.text = student.bio ?? '';
    }
    _resultsFuture = quizService.fetchStudentResults();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final quizService = Provider.of<QuizService>(context, listen: false);
    final success = await quizService.updateStudentProfile(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdated)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.updateFailed)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final student = quizService.currentStudent;
    final theme = Theme.of(context);

    if (student == null) {
      return Scaffold(body: Center(child: Text(AppLocalizations.of(context)!.notLoggedIn)));
    }

    return Scaffold(
      body: GlobalBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              _ProfileHeader(theme: theme),
              const SizedBox(height: 24),
              const SizedBox(height: 20),

              if (!_isEditing)
                _ProfileInfoDisplay(
                  student: student,
                  theme: theme,
                  onEdit: () => setState(() => _isEditing = true)
                )
              else
                _ProfileEditForm(
                  nameController: _nameController,
                  bioController: _bioController,
                  isLoading: _isLoading,
                  onCancel: () => setState(() => _isEditing = false),
                  onSave: _saveProfile,
                ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 16),
              _QuizHistorySection(resultsFuture: _resultsFuture),
              const SizedBox(height: 40),
              _LogoutButton(quizService: quizService),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final ThemeData theme;

  const _ProfileHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.primaryColor),
          tooltip: AppLocalizations.of(context)!.goBack,
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context)!.myProfile,
          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ProfileInfoDisplay extends StatelessWidget {
  final Student student;
  final ThemeData theme;
  final VoidCallback onEdit;

  const _ProfileInfoDisplay({
    required this.student,
    required this.theme,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(student.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(student.phone, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        const SizedBox(height: 20),
        if (student.bio != null && student.bio!.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Text(student.bio!, textAlign: TextAlign.center),
          ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: Text(AppLocalizations.of(context)!.editProfile),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 24),
        const Divider(),
        Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return SwitchListTile(
              title: Text(AppLocalizations.of(context)!.darkMode),
              subtitle: Text(AppLocalizations.of(context)!.toggleAppearance),
              value: themeProvider.isDarkMode,
              activeThumbColor: theme.primaryColor,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            );
          },
        ),
        const Divider(),
        Consumer<LanguageProvider>(
          builder: (context, langProvider, child) {
            final isEn = langProvider.currentLocale.languageCode == 'en';
            return SwitchListTile(
              title: const Text('English / عربي'),
              subtitle: const Text('Language / اللغة'),
              value: isEn,
              activeThumbColor: theme.primaryColor,
              onChanged: (_) {
                langProvider.toggleLanguage();
              },
            );
          },
        ),
      ],
    );
  }
}

class _ProfileEditForm extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController bioController;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ProfileEditForm({
    required this.nameController,
    required this.bioController,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.fullName, border: const OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: bioController,
          decoration: InputDecoration(labelText: AppLocalizations.of(context)!.bio, border: const OutlineInputBorder()),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: TextButton(onPressed: onCancel, child: Text(AppLocalizations.of(context)!.cancel)),
            ),
            Expanded(
              child: ElevatedButton(onPressed: isLoading ? null : onSave, child: isLoading ? const CircularProgressIndicator() : Text(AppLocalizations.of(context)!.save)),
            ),
          ],
        ),
      ],
    );
  }
}

class _QuizHistorySection extends StatelessWidget {
  final Future<List<QuizResult>>? resultsFuture;

  const _QuizHistorySection({required this.resultsFuture});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            AppLocalizations.of(context)!.quizHistory,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<QuizResult>>(
          future: resultsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final results = (snapshot.data ?? []).take(3).toList();
            if (results.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.noQuizzesCompleted, style: const TextStyle(color: Colors.grey)));
            }
            return Column(
              children: [
                ...results.map((r) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(r.examTitle ?? AppLocalizations.of(context)!.generalQuiz),
                    subtitle: Text(r.createdAt != null ? DateFormat('MMM d, y').format(r.createdAt!) : ''),
                    trailing: Text(
                      '${r.scorePercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.grade == 'F' ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                )),
                TextButton(
                  onPressed: () => context.push('/student_results'),
                  child: Text(AppLocalizations.of(context)!.viewAllHistory),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final QuizService quizService;

  const _LogoutButton({required this.quizService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: () {
        quizService.logoutStudent();
        context.go('/');
      },
      icon: const Icon(Icons.logout, color: Colors.red),
      label: Text(l10n.localeName == 'ar' ? 'تسجيل خروج' : 'Logout', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 54),
        side: const BorderSide(color: Colors.red),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
