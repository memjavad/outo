import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/quiz_service_facade.dart';
import '../../l10n/app_localizations.dart';
import '../../core/config/app_config.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoadingTg = false;
  Timer? _pollingTimer;
  String? _tgSessionId;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final quizService = Provider.of<QuizService>(context, listen: false);

    bool success;
    if (_isLogin) {
      success = await quizService.studentLogin(
        _phoneController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await quizService.studentRegister(
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _passwordController.text,
      );
    }

    if (mounted) {
      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(quizService.lastError ?? 'Authentication failed'),
          ),
        );
      }
    }
  }

  Future<void> _loginWithTelegram() async {
    final quizService = Provider.of<QuizService>(context, listen: false);

    final baseHost =
        AppConfig.productionHost.isNotEmpty
            ? AppConfig.productionHost
            : ((!kIsWeb && Platform.isAndroid)
                ? 'http://10.0.2.2'
                : 'http://localhost');

    _tgSessionId = const Uuid().v4();
    final url = Uri.parse(
      '$baseHost/server/telegram_login.php?session_id=$_tgSessionId',
    );

    setState(() => _isLoadingTg = true);

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.telegramBrowserError)));
        setState(() => _isLoadingTg = false);
      }
      return;
    }

    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final sessionData = await quizService.checkTgLogin(_tgSessionId!);
      if (sessionData != null && sessionData['status'] == 'authenticated') {
        timer.cancel();
        await quizService.setTelegramUser(sessionData);
        if (mounted) {
          setState(() => _isLoadingTg = false);
          context.go('/');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Decorative Asymmetric Floating Shapes
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withValues(alpha: 0.1),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.of(context).size.height * 0.05,
            right: -MediaQuery.of(context).size.width * 0.05,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.05),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hero Branding
                    Container(
                      width: 96,
                      height: 96,
                      margin: const EdgeInsets.only(bottom: 32),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.surfaceContainerHighest,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Icon(
                        LucideIcons.graduationCap,
                        size: 48,
                        color: colorScheme.primary,
                      ).animate().scale(
                        delay: 200.ms,
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                    ),
                    Text(
                      l10n.welcomeTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
                    const SizedBox(height: 12),
                    Text(
                      l10n.enterPhoneAndPassword,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 40),

                    // Main Login Card
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.04),
                            blurRadius: 30,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_isLogin)
                            Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          l10n.fullName.toUpperCase(),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.2,
                                              ),
                                        ),
                                      ),
                                      TextField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          hintText: l10n.fullName,
                                          prefixIcon: Icon(
                                            LucideIcons.user,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 100.ms)
                                .slideX(begin: 0.1),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    l10n.phoneNumber.toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                                TextField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    hintText: '05xxxxxxxx',
                                    prefixIcon: Icon(
                                      LucideIcons.phone,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),

                          Padding(
                            padding: const EdgeInsets.only(bottom: 32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 8,
                                  ),
                                  child: Text(
                                    l10n.password.toUpperCase(),
                                    style: theme.textTheme.labelMedium
                                        ?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                  ),
                                ),
                                TextField(
                                  controller: _passwordController,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(
                                      LucideIcons.lock,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  obscureText: true,
                                  textDirection: TextDirection.ltr,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1),

                          // Primary CTA
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 25,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primaryContainer,
                                ],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: quizService.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                              ),
                              child:
                                  quizService.isLoading
                                      ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                      : Text(
                                        _isLogin ? l10n.login : l10n.signUp,
                                      ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                          if (_isLogin) ...[
                            const SizedBox(height: 16),
                            // Soft Gradient Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.dividerColor.withValues(
                                            alpha: 0.0,
                                          ),
                                          theme.dividerColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    l10n.orLabel,
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.dividerColor,
                                          theme.dividerColor.withValues(
                                            alpha: 0.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ).animate().fadeIn(delay: 450.ms),
                            const SizedBox(height: 16),

                            // Premium Telegram Login Button
                            Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0088cc,
                                        ).withValues(alpha: 0.2),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        _isLoadingTg
                                            ? null
                                            : _loginWithTelegram,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: const Color(
                                        0xFF0088cc,
                                      ), // Telegram Blue
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                    ),
                                    icon: const Icon(
                                      LucideIcons.send,
                                      size: 20,
                                    ),
                                    label:
                                        _isLoadingTg
                                            ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                            : Text(
                                              l10n.loginWithTelegram,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: 450.ms)
                                .slideY(begin: 0.2),
                          ],

                          const SizedBox(height: 24),
                          TextButton(
                            onPressed:
                                () => setState(() => _isLogin = !_isLogin),
                            child: Text(
                              _isLogin
                                  ? l10n.dontHaveAccount
                                  : l10n.alreadyHaveAccount,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () => context.push('/login'),
                            child: Text(
                              l10n.adminTeacherLogin,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ).animate().fadeIn(delay: 600.ms),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (context.canPop())
            PositionedDirectional(
              top: MediaQuery.of(context).padding.top + 8,
              start: 16,
              child: IconButton(
                icon: Icon(Icons.close, color: colorScheme.primary, size: 32),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => context.pop(),
              ),
            ),
        ],
      ),
    );
  }
}
