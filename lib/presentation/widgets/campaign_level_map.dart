import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../domain/entities/entities.dart';

enum NodeState { locked, current, completed }

class CampaignLevelMap extends StatefulWidget {
  final List<Exam> exams;
  final Map<String, double> examScores;
  final Function(Exam) onNodeTap;

  const CampaignLevelMap({
    super.key,
    required this.exams,
    required this.examScores,
    required this.onNodeTap,
  });

  @override
  State<CampaignLevelMap> createState() => _CampaignLevelMapState();
}

class _CampaignLevelMapState extends State<CampaignLevelMap>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _unlockController;
  static const _audioChannel = MethodChannel('com.student_quiz_app/audio');

  int _previousScoreCount = 0;
  bool _isAnimatingUnlock = false;
  bool _hasPlayedUnlockSfx = false;
  int _newlyUnlockedIndex = -1;
  final double nodeHeight = 150.0;

  @override
  void initState() {
    super.initState();
    _previousScoreCount = widget.examScores.length;
    _unlockController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scrollController = ScrollController();

    // Fire up the ambient background acoustic engine via Native bridge
    _audioChannel.invokeMethod('playAmbient', {
      'asset': 'audio/jungle.wav',
      'volume': 0.15,
    });

    // Add physics detection listener for precise Pop sounds
    _unlockController.addListener(() {
      if (_isAnimatingUnlock &&
          _unlockController.value >= 0.8 &&
          !_hasPlayedUnlockSfx) {
        _hasPlayedUnlockSfx = true;
        _audioChannel.invokeMethod('playSfx', {
          'asset': 'audio/pop.wav',
          'volume': 0.6,
        });
      }
    });
  }

  int _getHighestUnlockedIndex() {
    int highest = 0;
    for (int i = 0; i < widget.exams.length; i++) {
      final exam = widget.exams[i];
      final bool hasPrereq =
          exam.prerequisiteExamId != null &&
          exam.prerequisiteExamId!.isNotEmpty;

      bool isLocked = false;
      if (hasPrereq) {
        final prereqScore = widget.examScores[exam.prerequisiteExamId!];
        isLocked = prereqScore == null || prereqScore < 50;
      } else if (i > 0) {
        // Auto-linear progression fallback
        final prevScore = widget.examScores[widget.exams[i - 1].id.toString()];
        isLocked = prevScore == null || prevScore < 50;
      }

      if (!isLocked) highest = i;
    }
    return highest;
  }

  @override
  void didUpdateWidget(CampaignLevelMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.examScores.length > _previousScoreCount) {
      _previousScoreCount = widget.examScores.length;
      _newlyUnlockedIndex = _getHighestUnlockedIndex();
      _hasPlayedUnlockSfx = false;

      setState(() {
        _isAnimatingUnlock = true;
      });

      _unlockController.forward(from: 0.0).then((_) {
        if (mounted) setState(() => _isAnimatingUnlock = false);
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _unlockController.dispose();
    _audioChannel.invokeMethod('stopAmbient');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalHeight = (widget.exams.length * nodeHeight) + 200.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.transparent,
                Colors.transparent,
                Colors.black,
              ],
              stops: [0.0, 0.12, 0.88, 1.0], // Darken top and bottom 12%
            ).createShader(bounds);
          },
          blendMode:
              BlendMode.dstOut, // Uses the gradient's alpha to erase the widget
          child: Stack(
            children: [
              const DeepAbyssLayer(),
              AmbientStarsLayer(
                totalHeight: totalHeight,
                scrollController: _scrollController,
                maxWidth: constraints.maxWidth,
                isDark: isDark,
                buildDecorations: _buildDecorations,
              ),
              // Foreground Interactive Canvas
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                reverse:
                    true, // Reversing makes it conceptually start at the bottom
                child: SizedBox(
                  height: totalHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // Environment Decorations (Clouds, Trees)
                      ..._buildDecorations(
                        totalHeight,
                        constraints.maxWidth,
                        isDark,
                      ),

                      // Painter for the dashed path
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _unlockController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: MapPathPainter(
                                count: widget.exams.length,
                                nodeHeight: nodeHeight,
                                totalHeight: totalHeight,
                                activeNodesCount:
                                    _isAnimatingUnlock
                                        ? _newlyUnlockedIndex
                                        : _getHighestUnlockedIndex(),
                                unlockProgress:
                                    _isAnimatingUnlock
                                        ? _unlockController.value
                                        : 1.0,
                              ),
                            );
                          },
                        ),
                      ),

                      // The Nodes
                      ...List.generate(widget.exams.length, (index) {
                        final exam = widget.exams[index];
                        final bool hasPrereq =
                            exam.prerequisiteExamId != null &&
                            exam.prerequisiteExamId!.isNotEmpty;

                        bool isLocked = false;
                        if (hasPrereq) {
                          final prereqScore =
                              widget.examScores[exam.prerequisiteExamId!];
                          isLocked = prereqScore == null || prereqScore < 50;
                        } else if (index > 0) {
                          // Auto-linear progression fallback
                          final prevScore =
                              widget.examScores[widget.exams[index - 1].id
                                  .toString()];
                          isLocked = prevScore == null || prevScore < 50;
                        }

                        final bool isCompleted = widget.examScores.containsKey(
                          exam.id.toString(),
                        );

                        NodeState state = NodeState.locked;
                        if (index == _newlyUnlockedIndex &&
                            _isAnimatingUnlock) {
                          // Force unlocked state visually but prevent full appearance until line draws
                          state =
                              _unlockController.value > 0.8
                                  ? NodeState.current
                                  : NodeState.locked;
                        } else if (isCompleted) {
                          state = NodeState.completed;
                        } else if (!isLocked) {
                          state = NodeState.current;
                        }

                        Widget node = MapNodePlacement(
                          index: index,
                          exam: exam,
                          state: state,
                          score: widget.examScores[exam.id.toString()],
                          nodeHeight: nodeHeight,
                          totalHeight: totalHeight,
                          screenWidth: constraints.maxWidth,
                          onTap: () => widget.onNodeTap(exam),
                        );

                        // Intense pop-in animation synchronized exactly when the path drawing reaches the castle
                        if (index == _newlyUnlockedIndex &&
                            _isAnimatingUnlock) {
                          node = AnimatedBuilder(
                            animation: _unlockController,
                            builder: (context, child) {
                              if (_unlockController.value < 0.8)
                                return const SizedBox(); // Hide until line finishes
                              return child!.animate().scaleXY(
                                begin: 0,
                                end: 1,
                                duration: 800.ms,
                                curve: Curves.elasticOut,
                              );
                            },
                            child: node,
                          );
                        }

                        return node;
                      }),
                    ],
                  ),
                ),
              ),
              CameraLensParticles(scrollController: _scrollController),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildDecorations(
    double totalHeight,
    double width,
    bool isDark, {
    int seed = 12345,
  }) {
    if (width == 0) return [];

    final math.Random random = math.Random(
      seed,
    ); // Deterministic seed for stable placement
    final List<Widget> stars = [];
    final int numStars =
        (totalHeight / 40).ceil(); // High density deep-space stars

    for (int i = 0; i < numStars; i++) {
      double y = random.nextDouble() * totalHeight;
      double x = random.nextDouble() * width;

      double size = 1.0 + random.nextDouble() * 3.0; // Tiny 1-4px stars

      Widget element = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              random.nextBool()
                  ? Colors.white.withOpacity(0.8)
                  : Colors.cyanAccent.withOpacity(0.6),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withOpacity(0.3),
              blurRadius: size * 2,
              spreadRadius: 1,
            ),
          ],
        ),
      );

      // Subtle atmospheric animations (twinkling and extreme slow drift)
      element = element
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .moveX(
            end: random.nextBool() ? 8 : -8,
            duration: Duration(milliseconds: 10000 + random.nextInt(5000)),
            curve: Curves.easeInOutSine,
          )
          .scaleXY(
            end: 1.5,
            duration: Duration(milliseconds: 3000 + random.nextInt(3000)),
          )
          .fade(
            end: 0.2,
            duration: Duration(milliseconds: 2000 + random.nextInt(2000)),
          );

      stars.add(Positioned(left: x, top: y, child: element));
    }

    return stars;
  }
}

class MapNodePlacement extends StatelessWidget {
  final int index;
  final Exam exam;
  final NodeState state;
  final double? score;
  final double nodeHeight;
  final double totalHeight;
  final double screenWidth;
  final VoidCallback onTap;

  const MapNodePlacement({
    super.key,
    required this.index,
    required this.exam,
    required this.state,
    this.score,
    required this.nodeHeight,
    required this.totalHeight,
    required this.screenWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double x = _getX(index, screenWidth);
    final double y = _getY(index, totalHeight, nodeHeight);

    return Positioned(
      left: x - 50, // Fixed center alignment width (100 / 2)
      top: y - 45,
      width: 100, // Lock the width so Column centers everything perfectly
      child: GestureDetector(
        onTap:
            state == NodeState.locked
                ? () {
                  _CampaignLevelMapState._audioChannel.invokeMethod('playSfx', {
                    'asset': 'audio/thud.wav',
                    'volume': 0.5,
                  }); // Heavy thud logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You must complete the previous Level to unlock this!',
                      ),
                    ),
                  );
                }
                : () {
                  _CampaignLevelMapState._audioChannel.invokeMethod('playSfx', {
                    'asset': 'audio/pop.wav',
                    'volume': 0.4,
                  }); // Bright magical confirm
                  onTap();
                },
        child: _buildNodeContent(context),
      ),
    );
  }

  Widget _buildNodeContent(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<BoxShadow> shadows = [];
    Color borderColor = Colors.white;
    double scale = 1.0;

    switch (state) {
      case NodeState.locked:
        borderColor = isDark ? Colors.grey.shade600 : Colors.grey.shade500;
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ];
        break;
      case NodeState.current:
        borderColor = Colors.orangeAccent;
        shadows = [
          BoxShadow(
            color: Colors.deepOrange.withOpacity(0.8),
            blurRadius: 20,
            spreadRadius: 6,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: Colors.yellow.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 6,
            offset: const Offset(0, 6),
          ),
        ];
        scale = 1.25; // Pop the current level higher
        break;
      case NodeState.completed:
        borderColor = const Color(0xFFFFF8DC);
        shadows = [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 6,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ];
        break;
    }

    Widget nodeCore = Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 3D Programmatic Pedestal Base
        Positioned(
          bottom: -15, // Reduced offset to match smaller scale
          child: Transform(
            alignment: FractionalOffset.center,
            transform:
                Matrix4.identity()
                  ..setEntry(3, 2, 0.002) // Perspective depth
                  ..rotateX(1.3), // Tilt flat
            child: Container(
              width: 100, // Reduced from 140
              height: 100, // Reduced from 140
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    state == NodeState.locked
                        ? Colors.blueGrey.shade800
                        : Colors.cyanAccent.withOpacity(0.2), // Core Air
                    state == NodeState.locked
                        ? Colors.blueGrey.shade900
                        : const Color(0xFF003366).withOpacity(0.6), // Surface
                    state == NodeState.locked
                        ? Colors.black
                        : const Color(
                          0xFF001133,
                        ).withOpacity(0.95), // Platform Edge
                    state == NodeState.locked
                        ? Colors.grey.shade700
                        : Colors.cyanAccent.withOpacity(
                          0.8,
                        ), // Bevel Specular Light
                    state == NodeState.locked
                        ? Colors.black
                        : const Color(0xFF002244), // Outer Bevel Rim
                  ],
                  stops: const [0.0, 0.5, 0.85, 0.95, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        state == NodeState.locked
                            ? Colors.black.withOpacity(0.8)
                            : Colors.cyan.withOpacity(0.4),
                    blurRadius: 15, // Reduced shadow scale
                    spreadRadius: 3,
                  ),
                  BoxShadow(
                    // Depth shadow plunging into the abyss
                    color: Colors.black.withOpacity(0.9),
                    blurRadius: 10,
                    offset: const Offset(0, 25), // Reduced drop distance
                  ),
                  BoxShadow(
                    // Inner Rim shadow for 3D thickness
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 10,
                    offset: const Offset(
                      0,
                      -5,
                    ), // Simulates the bottom edge being dark
                  ),
                ],
                border: Border.all(
                  color:
                      state == NodeState.locked ? Colors.white24 : Colors.cyan,
                  width: 3,
                ),
              ),
            ),
          ),
        ),
        // The Interactive Castle
        Container(
          width: 56, // Reduced from 76
          height: 56, // Reduced from 76
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: shadows,
            border: Border.all(
              color: borderColor,
              width: state == NodeState.completed ? 4 : 2,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              state == NodeState.completed
                  ? 'assets/images/castle_burning.png'
                  : 'assets/images/castle_psychology.png',
              fit: BoxFit.cover,
              color:
                  state == NodeState.locked
                      ? Colors.black.withOpacity(0.5)
                      : null,
              colorBlendMode:
                  state == NodeState.locked ? BlendMode.darken : null,
            ),
          ),
        ),
      ],
    );

    // Add prominent pulsing and glowing animations if it's the current target level
    if (state == NodeState.current) {
      nodeCore = nodeCore
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(end: 1.08, duration: 1200.ms, curve: Curves.easeInOutSine)
          .tint(
            color: Colors.white,
            end: 0.35,
            duration: 1200.ms,
            curve: Curves.easeInOutSine,
          );
    }

    Widget fullNode = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium Metallic Level number badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors:
                  state == NodeState.locked
                      ? [
                        Colors.blueGrey.shade700,
                        Colors.blueGrey.shade900,
                      ] // Iron for locked
                      : [
                        const Color(0xFFFFD700),
                        const Color(0xFFB8860B),
                      ], // Gold for unlocked
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  state == NodeState.locked
                      ? Colors.blueGrey.shade500
                      : Colors.yellow.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.6),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            'Lvl ${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color:
                  state == NodeState.locked ? Colors.white70 : Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(
          height: 14,
        ), // Pushed badge higher from the pedestal glare
        // Interactive Node
        Transform.scale(scale: scale, child: nodeCore),
        const SizedBox(
          height: 20,
        ), // Pushed text lower to clear the 3D drop shadows
        // Title (Truncated)
        SizedBox(
          width: 100,
          child: Text(
            exam.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(
                0.9,
              ), // Always light against the dark space background
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(
                    0.8,
                  ), // Softer, darker text backing
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
        if (state == NodeState.completed && score != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (starIndex) {
              bool isEarned = false;
              if (starIndex == 0 && score! >= 50) isEarned = true;
              if (starIndex == 1 && score! >= 75) isEarned = true;
              if (starIndex == 2 && score! >= 90) isEarned = true;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.0),
                child: Icon(
                  isEarned ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isEarned ? Colors.amberAccent : Colors.white54,
                  size: 16,
                  shadows: [
                    if (isEarned)
                      const Shadow(color: Colors.orange, blurRadius: 4),
                  ],
                ),
              );
            }),
          ),
        ],
      ],
    );

    // Base staggered delay
    var animatedNode = fullNode
        .animate(delay: (index * 150).ms)
        .fadeIn(duration: 400.ms);

    if (state == NodeState.locked) {
      // Heavy stone physics: Thuds down from above, no hovering
      animatedNode = animatedNode.moveY(
        begin: -60,
        end: 0,
        duration: 800.ms,
        curve: Curves.bounceOut,
      );
    } else if (state == NodeState.current) {
      // Energetic Pop and strong hover mechanics
      animatedNode = animatedNode
          .scaleXY(
            begin: 0,
            end: 1.0,
            duration: 600.ms,
            curve: Curves.easeOutBack,
          )
          .then(delay: 200.ms)
          .moveY(
            begin: 0,
            end: -8,
            duration: 1200.ms,
            curve: Curves.easeInOutSine,
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true));
    } else if (state == NodeState.completed) {
      // Shimmering Gold Coin physics: Spins in, subtle ambient hover
      animatedNode = animatedNode
          .rotate(
            begin: 0.5,
            end: 0,
            duration: 800.ms,
            curve: Curves.easeOutBack,
          )
          .scaleXY(
            begin: 0,
            end: 1.0,
            duration: 800.ms,
            curve: Curves.easeOutBack,
          )
          .then(delay: 200.ms)
          .moveY(
            begin: 0,
            end: -3,
            duration: 2000.ms,
            curve: Curves.easeInOutSine,
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true));
    }

    return animatedNode;
  }
}

class MapPathPainter extends CustomPainter {
  final int count;
  final double nodeHeight;
  final double totalHeight;
  final int activeNodesCount;
  final double unlockProgress;

  MapPathPainter({
    required this.count,
    required this.nodeHeight,
    required this.totalHeight,
    required this.activeNodesCount,
    required this.unlockProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (count < 2) return;

    // Active Bright Paths (Neon blue / Cyan neural pathways)
    final basePathPaint =
        Paint()
          ..color = const Color(0xFF003366).withOpacity(
            0.9,
          ) // Deep blue outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.solid,
            4.0,
          ); // Outer glow

    final dirtPathPaint =
        Paint()
          ..color =
              Colors
                  .cyanAccent
                  .shade100 // Pure intense cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(
            BlurStyle.solid,
            2.0,
          ); // Core hot glow

    // Locked Faded Paths
    final lockedBasePaint =
        Paint()
          ..color = Colors.black.withOpacity(
            0.8,
          ) // Darker outer shadow for locked paths
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round;

    final lockedDirtPaint =
        Paint()
          ..color = const Color(0xFF1976D2).withOpacity(
            0.5,
          ) // Highly visible blue dormant neural core
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round;

    // Procedural 3D Drop Shadow (The depth illusion)
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 24
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    final fullPath = Path();
    for (int i = 0; i < count; i++) {
      double currentX = _getX(i, size.width);
      double currentY = _getY(i, totalHeight, nodeHeight);
      if (i == 0) {
        fullPath.moveTo(currentX, currentY);
      } else {
        double prevX = _getX(i - 1, size.width);
        double prevY = _getY(i - 1, totalHeight, nodeHeight);
        double controlY = (currentY + prevY) / 2;
        fullPath.cubicTo(
          prevX,
          controlY,
          currentX,
          controlY,
          currentX,
          currentY,
        );
      }
    }

    // Draw the massive procedural drop shadow physically lower on the screen
    final offsetShadowPath = fullPath.shift(const Offset(10, 25));
    canvas.drawPath(offsetShadowPath, shadowPaint);

    // Always draw the full generic locked path beneath everything
    canvas.drawPath(fullPath, lockedBasePaint);
    _drawDashedPath(canvas, fullPath, lockedDirtPaint);

    if (activeNodesCount <= 0 && unlockProgress <= 0) return;

    // Dynamically build and trace the active unlocked path
    final activePath = Path();
    for (int i = 0; i <= activeNodesCount; i++) {
      double currentX = _getX(i, size.width);
      double currentY = _getY(i, totalHeight, nodeHeight);

      if (i == 0) {
        activePath.moveTo(currentX, currentY);
      } else {
        double prevX = _getX(i - 1, size.width);
        double prevY = _getY(i - 1, totalHeight, nodeHeight);
        double controlY = (currentY + prevY) / 2;

        if (i == activeNodesCount && unlockProgress < 1.0) {
          // Extract Sub-Path Metric specifically for the tracing animation
          final tempPath = Path();
          tempPath.moveTo(prevX, prevY);
          tempPath.cubicTo(
            prevX,
            controlY,
            currentX,
            controlY,
            currentX,
            currentY,
          );

          for (PathMetric metric in tempPath.computeMetrics()) {
            final extract = metric.extractPath(
              0,
              metric.length * unlockProgress,
            );
            activePath.addPath(extract, Offset.zero);
          }
        } else {
          activePath.cubicTo(
            prevX,
            controlY,
            currentX,
            controlY,
            currentX,
            currentY,
          );
        }
      }
    }

    // Overlay the active tracing path
    canvas.drawPath(activePath, basePathPaint);
    _drawDashedPath(canvas, activePath, dirtPathPaint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (PathMetric measurePath in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < measurePath.length) {
        double length = draw ? 22.0 : 8.0;
        if (draw) {
          canvas.drawPath(
            measurePath.extractPath(distance, distance + length),
            paint,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Math helpers
double _getX(int index, double width) {
  double center = width / 2;
  double amplitude = width * 0.35; // 35% of screen width variance
  return center + math.sin(index * 1.5) * amplitude;
}

double _getY(int index, double totalHeight, double nodeHeight) {
  // Offset +20 to physically anchor the path to the isometric base/gate of the node
  return totalHeight - 140 - (index * nodeHeight) + 20;
}

class DeepAbyssLayer extends StatelessWidget {
  const DeepAbyssLayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF01001A), // Extreme deep space blue
            Color(0xFF000000), // Void
            Color(0xFF050012), // Faint violet tint
            Color(0xFF000000), // Void
          ],
          stops: [0.0, 0.4, 0.8, 1.0],
        ),
      ),
    );
  }
}

class AmbientStarsLayer extends StatelessWidget {
  final double totalHeight;
  final ScrollController scrollController;
  final double maxWidth;
  final bool isDark;
  final List<Widget> Function(double, double, bool, {int seed})
  buildDecorations;

  const AmbientStarsLayer({
    super.key,
    required this.totalHeight,
    required this.scrollController,
    required this.maxWidth,
    required this.isDark,
    required this.buildDecorations,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -totalHeight, // Allow spanning the entire virtual scroll area
      left: 0,
      right: 0,
      height: totalHeight * 2, // Doubled height to cover parallax offset
      child: AnimatedBuilder(
        animation: scrollController,
        builder: (context, child) {
          double offset =
              scrollController.hasClients ? scrollController.offset : 0;
          return Transform.translate(
            offset: Offset(0, offset * 0.4),
            child: child,
          );
        },
        child: SizedBox(
          width: maxWidth,
          child: Stack(
            // Generate unique deep-space stars
            children: buildDecorations(
              totalHeight * 2,
              maxWidth,
              isDark,
              seed: 777,
            ),
          ),
        ),
      ),
    );
  }
}

class CameraLensParticles extends StatelessWidget {
  final ScrollController scrollController;

  const CameraLensParticles({super.key, required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: scrollController,
          builder: (context, child) {
            double offset =
                scrollController.hasClients ? scrollController.offset : 0;
            return Transform.translate(
              // Move faster than the scroll to simulate objects very close to screen
              offset: Offset(0, offset * 1.3),
              child: child,
            );
          },
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/midground_clouds.png'),
                repeat: ImageRepeat.repeat,
                opacity: 0.25,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
