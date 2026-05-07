import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import '../providers/quiz_service_facade.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final quizService = Provider.of<QuizService>(context, listen: false);
    final success = await quizService.adminLogin(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      context.go('/admin');
    } else if (mounted) {
      setState(() {
        _errorMessage = 'invalid';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Decorative Asymmetric Floating Shapes
          _DecorativeShape(
            top: -MediaQuery.of(context).size.height * 0.1,
            left: -MediaQuery.of(context).size.width * 0.1,
            size: 256,
            color: colorScheme.secondary.withValues(alpha: 0.1),
          ),
          _DecorativeShape(
            bottom: -MediaQuery.of(context).size.height * 0.05,
            right: -MediaQuery.of(context).size.width * 0.05,
            size: 320,
            color: colorScheme.primaryContainer.withValues(alpha: 0.05),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroBranding(colorScheme: colorScheme, theme: theme),
                    const SizedBox(height: 40),
                    _LoginForm(
                      errorMessage: _errorMessage,
                      isLoading: _isLoading,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      onLogin: _login,
                      l10n: l10n,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 8,
            start: 16,
            child: IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: Icon(Icons.close, color: colorScheme.primary, size: 32),
              onPressed: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecorativeShape extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double size;
  final Color color;

  const _DecorativeShape({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size * 0.3125, // equivalent to 80/256 or 100/320
              spreadRadius: size * 0.3125,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBranding extends StatelessWidget {
  final ColorScheme colorScheme;
  final ThemeData theme;

  const _HeroBranding({required this.colorScheme, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            Icons.admin_panel_settings,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        Text(
          "Admin Portal",
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Elevated Access Required",
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LoginForm extends StatelessWidget {
  final String errorMessage;
  final bool isLoading;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final AppLocalizations l10n;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _LoginForm({
    required this.errorMessage,
    required this.isLoading,
    required this.usernameController,
    required this.passwordController,
    required this.onLogin,
    required this.l10n,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32.0),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                l10n.invalidLogin,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          _InputField(
            label: l10n.username.toUpperCase(),
            hint: l10n.username,
            icon: Icons.person,
            controller: usernameController,
            theme: theme,
            colorScheme: colorScheme,
            padding: const EdgeInsets.only(bottom: 16),
          ),

          _InputField(
            label: l10n.password.toUpperCase(),
            hint: l10n.password,
            icon: Icons.lock,
            controller: passwordController,
            obscureText: true,
            theme: theme,
            colorScheme: colorScheme,
            padding: const EdgeInsets.only(bottom: 32),
          ),

          // Primary CTA
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.2),
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
              onPressed: isLoading ? null : onLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(l10n.login),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final EdgeInsetsGeometry padding;

  const _InputField({
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    required this.theme,
    required this.colorScheme,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          TextField(
            controller: controller,
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
