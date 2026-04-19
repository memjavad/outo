import 'package:flutter/material.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/utils/platform_utils.dart';

class GlobalBackground extends StatelessWidget {
  final Widget child;

  const GlobalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: Stack(
        children: [
          // Decorative Asymmetric Floating Shapes
          Positioned(
            top: -MediaQuery.sizeOf(context).height * 0.1,
            left: -MediaQuery.sizeOf(context).width * 0.1,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.secondary.withOpacity(0.08),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.secondary.withOpacity(0.08),
                    blurRadius: 80,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -MediaQuery.sizeOf(context).height * 0.05,
            right: -MediaQuery.sizeOf(context).width * 0.05,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withOpacity(0.04),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primaryContainer.withOpacity(0.04),
                    blurRadius: 100,
                    spreadRadius: 100,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(child: child),
        ],
      ),
    );
  }
}
