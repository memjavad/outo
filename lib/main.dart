import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/quiz_screen.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_admin_screen.dart';
import 'presentation/screens/results_screen.dart';
import 'presentation/screens/review_screen.dart';
import 'presentation/screens/add_question_screen.dart';
import 'presentation/screens/edit_question_screen.dart';
import 'domain/entities/entities.dart';
import 'presentation/providers/quiz_service_facade.dart';
import 'core/localization/language_provider.dart';
import 'core/utils/platform_utils.dart';
import 'core/config/app_config.dart';
import 'core/config/app_settings.dart';
import 'core/theme/theme_provider.dart';
import 'theme/app_theme.dart';
import 'presentation/screens/student_login_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/student_results_screen.dart';
import 'presentation/screens/leaderboard_screen.dart';
import 'presentation/screens/exam_instructions_screen.dart';
import 'presentation/screens/campaign_exams_screen.dart';
import 'presentation/screens/standard_exams_screen.dart';
import 'presentation/screens/student_essays_screen.dart';
import 'presentation/screens/store_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_quill/flutter_quill.dart';

// Dev workaround for self-signed certificates
class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  // Allow self-signed certs for dev server
  HttpOverrides.global = DevHttpOverrides();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final service = QuizService();
          service.init();
          return service;
        }),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const StudentQuizApp(),
    ),
  );
}

extension HexColor on String {
  Color toColorFromHex() {
    final hexCode = replaceAll('#', '');
    if (hexCode.length == 6) {
      return Color(int.parse('FF$hexCode', radix: 16));
    }
    return const Color(0xFF673AB7);
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const MainAdminScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>? ?? {};
        return QuizScreen(
          studentName: extra['studentName'] as String? ?? 'Student',
          entryGpsLocation: extra['entryGpsLocation'] as String?,
          exam: extra['exam'] as Exam?,
        );
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null || extra['result'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ResultsScreen(
          result: extra['result'] as QuizResult,
          questions: extra['questions'] as List<QuizQuestion>,
          selectedAnswers: extra['selectedAnswers'] as Map<int, dynamic>,
          allowReview: extra['allowReview'] as bool? ?? false,
          isEssay: extra['isEssay'] as bool? ?? false,
          exam: extra['exam'] as Exam?,
        );
      },
    ),
    GoRoute(
      path: '/review',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null || extra['questions'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ReviewScreen(
          questions: extra['questions'] as List<QuizQuestion>,
          selectedAnswers: extra['selectedAnswers'] as Map<int, dynamic>,
        );
      },
    ),
    GoRoute(
      path: '/admin/add_question',
      builder: (context, state) => const AddQuestionScreen(),
    ),
    GoRoute(
      path: '/store',
      builder: (context, state) => const StoreScreen(),
    ),
    GoRoute(
      path: '/admin/edit_question',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        if (extra == null || extra['question'] == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/admin'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return EditQuestionScreen(
          question: extra['question'] as QuizQuestion,
        );
      },
    ),
    GoRoute(
      path: '/student_login',
      builder: (context, state) => const StudentLoginScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/student_results',
      builder: (context, state) => const StudentResultsScreen(),
    ),
    GoRoute(
      path: '/campaign_exams',
      builder: (context, state) => const CampaignExamsScreen(),
    ),
    GoRoute(
      path: '/standard_exams',
      builder: (context, state) => const StandardExamsScreen(),
    ),
    GoRoute(
      path: '/essays_student',
      builder: (context, state) => const StudentEssaysScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/exam_instructions',
      builder: (context, state) {
        final exam = state.extra as Exam?;
        if (exam == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return ExamInstructionsScreen(exam: exam);
      },
    ),
  ],
);

class StudentQuizApp extends StatelessWidget {
  const StudentQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<QuizService, LanguageProvider, ThemeProvider>(
      builder: (context, quizService, languageProvider, themeProvider, child) {
        final settings = quizService.appSettings ?? AppSettings.defaultSettings();
        final primaryColor = settings.primaryColorHex.toColorFromHex();

        // Convert backend string to FlexScheme Enum
        final FlexScheme activeScheme = FlexScheme.values.firstWhere(
          (e) => e.name == settings.flexColorScheme,
          orElse: () => FlexScheme.blueWhale,
        );

        // #16: Smooth page transition animations
        const pageTransitions = PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          },
        );

        return MaterialApp.router(
          title: settings.appTitle,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English
            Locale('ar', ''), // Arabic
          ],
          locale: languageProvider.currentLocale,
          // #15: Light theme (Digital Curator Design System)
          theme: AppTheme.getLightTheme(primaryColor).copyWith(
            pageTransitionsTheme: pageTransitions,
          ),
          // #15: Dark theme (Flex Color Scheme fallback for dark mode)
          darkTheme: FlexThemeData.dark(
            scheme: activeScheme,
            surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
            blendLevel: 13,
            subThemesData: const FlexSubThemesData(
              blendOnLevel: 20,
              useMaterial3Typography: true,
              useM2StyleDividerInM3: true,
              defaultRadius: 16.0,
              buttonMinSize: Size(64, 52),
              elevatedButtonRadius: 30.0,
              elevatedButtonElevation: 2.0,
              cardRadius: 24.0,
              cardElevation: 8.0,
              inputDecoratorIsFilled: true,
              inputDecoratorBorderType: FlexInputBorderType.outline,
              inputDecoratorRadius: 16.0,
              inputDecoratorUnfocusedBorderIsColored: false,
            ),
            useMaterial3ErrorColors: true,
            visualDensity: FlexColorScheme.comfortablePlatformDensity,
            useMaterial3: true,
            swapLegacyOnMaterial3: true,
            fontFamily: GoogleFonts.inter().fontFamily,
            textTheme: GoogleFonts.notoSansArabicTextTheme(ThemeData.dark().textTheme),
            pageTransitionsTheme: pageTransitions,
          ).copyWith(
            colorScheme: FlexThemeData.dark(scheme: activeScheme).colorScheme.copyWith(
              primary: primaryColor,
              surface: const Color(0xFF0F172A), // Slate 900
              surfaceContainerHighest: const Color(0xFF1E293B), // Slate 800
            ),
            cardTheme: const CardThemeData(
              color: Color(0xFF1E293B), // Slate 800
              elevation: 8,
              shadowColor: Color(0x40000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(24)),
                side: BorderSide(color: Color(0x1AFFFFFF), width: 1), // Subtle glass border
              ),
            ),
          ),
          themeMode: themeProvider.isLoaded ? themeProvider.themeMode : ThemeMode.system, // Fetch from provider
        );
      },
    );
  }
}

