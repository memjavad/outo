import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import '../../domain/entities/entities.dart';
import '../widgets/global_background.dart';
import '../providers/quiz_service_facade.dart';
import '../../core/utils/platform_utils.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class ExamInstructionsScreen extends StatefulWidget {
  final Exam exam;

  const ExamInstructionsScreen({super.key, required this.exam});

  @override
  State<ExamInstructionsScreen> createState() => _ExamInstructionsScreenState();
}

class _ExamInstructionsScreenState extends State<ExamInstructionsScreen> {
  bool _isStarting = false;

  Future<void> _validateAndStartExam() async {
    final quizService = Provider.of<QuizService>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final exam = widget.exam;

    setState(() {
      _isStarting = true;
    });

    if (exam.examStartDate.isNotEmpty || exam.examEndDate.isNotEmpty) {
      DateTime now = DateTime.now();
      if (exam.examStartDate.isNotEmpty) {
        try {
          DateTime start = DateTime.parse(exam.examStartDate);
          if (now.isBefore(start)) {
            final format = DateFormat('MMM d, y h:mm a');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.examNotStarted(format.format(start))), duration: const Duration(seconds: 4)));
              setState(() => _isStarting = false);
            }
            return;
          }
        } catch (_) {}
      }

      if (exam.examEndDate.isNotEmpty) {
        try {
          DateTime end = DateTime.parse(exam.examEndDate);
          if (now.isAfter(end)) {
            final format = DateFormat('MMM d, y h:mm a');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.examEnded(format.format(end))), duration: const Duration(seconds: 4)));
              setState(() => _isStarting = false);
            }
            return;
          }
        } catch (_) {}
      }
    }

    String? gpsLocation;

    if (exam.detectVpn) {
      bool vpnActive = false;
      try {
        final interfaces = await NetworkInterface.list(includeLoopback: false, type: InternetAddressType.any);
        for (var interface in interfaces) {
          if (interface.name.toLowerCase().contains("tun") || interface.name.toLowerCase().contains("ppp") || interface.name.toLowerCase().contains("pptp")) {
            vpnActive = true;
            break;
          }
        }
      } catch (_) { vpnActive = false; }
      
      if (vpnActive) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.vpnDetected)));
          setState(() => _isStarting = false);
        }
        return;
      }
    }

    if (exam.requireBiometrics && isMobilePlatform) {
      final LocalAuthentication auth = LocalAuthentication();
      bool authenticated = false;
      try {
        authenticated = await auth.authenticate(localizedReason: 'Let OS verify your identity to start the exam');
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Biometric auth failed: ${e.toString()}')));
          setState(() => _isStarting = false);
        }
        return;
      }
      
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.biometricFailed)));
          setState(() => _isStarting = false);
        }
        return;
      }
    }

    if (exam.requireGps) {
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Location services are disabled.');

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw Exception('Location permissions are denied');
        }
        if (permission == LocationPermission.deniedForever) throw Exception('Location permissions permanently denied.');

        Position position = await Geolocator.getCurrentPosition();
        gpsLocation = '${position.latitude}, ${position.longitude}';
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS required: ${e.toString()}')));
          setState(() => _isStarting = false);
        }
        return;
      }
    }

    final fetchedQuestions = await quizService.fetchQuestionsForExam(exam.id);
    if (fetchedQuestions.isEmpty && exam.examType != 'essay') {
      if (mounted) {
        setState(() => _isStarting = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.localeName == 'ar' ? 'لا يوجد أسئلة لهذا الامتحان' : 'This exam has no questions.')));
      }
      return;
    }

    if (mounted) {
      setState(() => _isStarting = false);
      context.pushReplacement('/quiz', extra: {
        'studentName': quizService.currentStudent!.name,
        'entryGpsLocation': gpsLocation,
        'exam': exam,
      });
    }
  }

  Widget _buildRuleItem(IconData icon, String title, String description, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7), fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final l10n = AppLocalizations.of(context)!;
    final exam = widget.exam;

    return Scaffold(
      body: GlobalBackground(
        child: Column(
          children: [
            // Custom Immersive Header
            Padding(
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
                      exam.examType == 'campaign'
                          ? (l10n.localeName == 'ar' ? 'أوامر المستوى' : 'Level Rules')
                          : exam.examType == 'essay'
                              ? (l10n.localeName == 'ar' ? 'تعليمات الواجب' : 'Essay Instructions')
                              : l10n.examInstructions,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button for centering
                ],
              ),
            ),
            Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 36, color: theme.primaryColor),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          exam.title,
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  if (exam.description != null && exam.description!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(exam.description!, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.grey)),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    exam.examType == 'campaign'
                        ? (l10n.localeName == 'ar' ? 'شروط النصر' : 'Victory Conditions')
                        : exam.examType == 'essay' 
                            ? (l10n.localeName == 'ar' ? 'معايير التقييم والوقت' : 'Evaluation Criteria & Time Limit')
                            : l10n.rulesAndParameters, 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                  ),
                  const SizedBox(height: 16),
                  
                  if (exam.examType == 'campaign') ...[
                    Builder(
                      builder: (context) {
                        int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(exam.title)?.group(0) ?? '0') ?? 0;
                        int fuseSeconds = 30;
                        if (levelMatch > 150) fuseSeconds = 10;
                        else if (levelMatch > 100) fuseSeconds = 15;
                        else if (levelMatch > 50) fuseSeconds = 20;
                        else if (levelMatch > 25) fuseSeconds = 25;
                        
                        return Column(
                          children: [
                            _buildRuleItem(
                              LucideIcons.flame, 
                              l10n.localeName == 'ar' ? 'فتيل الإجابة' : 'Burning Fuse Timer', 
                              l10n.localeName == 'ar' ? 'لديك $fuseSeconds ثانية صعبة لكل سؤال في هذا المستوى.' : 'You have exactly $fuseSeconds seconds to survive each question in this level.', 
                              Colors.deepOrange
                            ),
                            _buildRuleItem(
                              LucideIcons.star, 
                              l10n.localeName == 'ar' ? 'مرتبة ٣ نجوم' : '3-Star Mastery', 
                              l10n.localeName == 'ar' ? 'حقق نسبة ٩٠٪ للنجوم الثلاثة. السقوط تحت ٥٠٪ يعني الإقصاء المستمر.' : 'Achieve 90% accuracy for 3 stars. Falling below 50% means instant failure.', 
                              Colors.amber
                            ),
                            _buildRuleItem(
                              LucideIcons.zap, 
                              l10n.localeName == 'ar' ? 'مضاعف السرعة' : 'Combo Multiplier', 
                              l10n.localeName == 'ar' ? 'سلسلة الإجابات الصحيحة تضرب مجموع نقاطك لتصل إلى أعلى القمة!' : 'Stringing correct answers together triples your score pushing you up the Leaderboard!', 
                              Colors.purpleAccent
                            ),
                          ]
                        );
                      }
                    ),
                  ] else ...[
                    _buildRuleItem(
                      LucideIcons.timer, 
                      l10n.timeLimit, 
                      exam.examType == 'essay'
                          ? (l10n.localeName == 'ar' ? 'لديك ${exam.examTimerMinutes} دقيقة للإجابة.' : 'You have ${exam.examTimerMinutes} minutes to complete this essay.')
                          : l10n.minutesTotalLimit(exam.examTimerMinutes.toString()), 
                      Colors.orange
                    ),
                  ],
                  
                  if (exam.examType == 'essay') ...[
                    _buildRuleItem(
                      LucideIcons.spellCheck, 
                      l10n.localeName == 'ar' ? 'القواعد واللغة' : 'Grammar & Mechanics', 
                      l10n.localeName == 'ar' ? 'سيتم التقييم على النحو النحوي والإملائي وعلامات الترقيم.' : 'Evaluated on syntax, spelling, punctuation, and structural mechanics.', 
                      Colors.blue
                    ),
                    _buildRuleItem(
                      LucideIcons.bookOpen, 
                      l10n.localeName == 'ar' ? 'المحتوى والمعرفة' : 'Content & Knowledge', 
                      l10n.localeName == 'ar' ? 'التركيز على دقة وعمق المعلومات ومدى ارتباطها بالموضوع.' : 'Focused on accuracy, depth of information, and relevance to the central topic.', 
                      Colors.indigo
                    ),
                    _buildRuleItem(
                      LucideIcons.layers, 
                      l10n.localeName == 'ar' ? 'التنظيم والهيكلة' : 'Organization', 
                      l10n.localeName == 'ar' ? 'التقييم استناداً إلى تسلسل الأفكار وبناء الفقرات.' : 'Evaluated on logical flow, paragraph structure, and clear transitions.', 
                      Colors.teal
                    ),
                    _buildRuleItem(
                      LucideIcons.lightbulb, 
                      l10n.localeName == 'ar' ? 'الإبداع والابتكار' : 'Creativity & Originality', 
                      l10n.localeName == 'ar' ? 'الأصالة في الطرح، الرؤية الشخصية، والأسلوب المتميز.' : 'Originality in thought, personal perspective, and engaging voice.', 
                      Colors.purple
                    ),
                  ] else ...[
                    if (exam.questionTimerSeconds > 0)
                      _buildRuleItem(
                        LucideIcons.hourglass, 
                        l10n.perQuestionLimit, 
                        l10n.secondsPerQuestionLimit(exam.questionTimerSeconds.toString()), 
                        Colors.deepOrange
                      ),
                      
                    if (exam.randomizeQuestions || exam.randomizeOptions)
                      _buildRuleItem(
                        LucideIcons.shuffle, 
                        l10n.randomized, 
                        l10n.randomizedDesc, 
                        Colors.blue
                      ),
                  ],

                  if (exam.requireGps)
                    _buildRuleItem(
                      LucideIcons.mapPin, 
                      l10n.locationTracking, 
                      l10n.locationTrackingDesc, 
                      Colors.red
                    ),

                  if (exam.detectVpn)
                    _buildRuleItem(
                      LucideIcons.shieldAlert, 
                      l10n.noVpnAllowed, 
                      l10n.noVpnAllowedDesc, 
                      Colors.redAccent
                    ),

                  if (exam.requireBiometrics)
                    _buildRuleItem(
                      LucideIcons.fingerprint, 
                      l10n.biometricVerification, 
                      l10n.biometricVerificationDesc, 
                      Colors.purple
                    ),
                    
                  if (exam.recordScreen || exam.preventScreenshots)
                    _buildRuleItem(
                      LucideIcons.monitorOff, 
                      l10n.screenProtection, 
                      exam.recordScreen ? l10n.screenRecordDesc : l10n.preventScreenshotsDesc, 
                      Colors.indigo
                    ),
                ],
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 24, 
              right: 24, 
              top: 24, 
              bottom: MediaQuery.of(context).padding.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -10))
              ]
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isStarting ? null : _validateAndStartExam,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                icon: _isStarting ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(LucideIcons.checkCircle),
                label: Text(
                  _isStarting 
                    ? l10n.verifyingContext 
                    : exam.examType == 'campaign'
                        ? (l10n.localeName == 'ar' ? 'أنا مستعد. ابدأ التحدي' : 'I am Ready. Begin Level')
                        : (exam.examType == 'essay' ? (l10n.localeName == 'ar' ? 'أوافق. ابدأ الواجب' : 'I Accept. Begin Essay') : l10n.acceptBeginExam), 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
