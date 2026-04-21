import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'quiz_loading_state.dart';
import 'quiz_top_header.dart';
import 'quiz_bottom_navigation.dart';
import 'quiz_main_content.dart';
// Import removed
import '../../domain/entities/entities.dart';
import '../providers/quiz_service_facade.dart';
import '../../core/utils/platform_utils.dart';
import 'package:go_router/go_router.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

// Security and anti-cheating imports removed due to compatibility issues on modern Android.
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart' as quill;

Map<String, dynamic> _decodeMap(String data) =>
    jsonDecode(data) as Map<String, dynamic>;

class QuizScreen extends StatefulWidget {
  final String studentName;
  final String? entryGpsLocation;
  final Exam? exam;

  const QuizScreen({
    super.key,
    required this.studentName,
    this.entryGpsLocation,
    this.exam,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalCampaignPoints = 0;
  int _currentCombo = 0;
  Map<int, dynamic> _selectedAnswers = {};
  Map<int, int> _answerTimes = {};
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  Timer? _autoSaveTimer;
  Timer? _heartbeatTimer;
  int _timeRemainingSeconds = 0;
  int _questionTimeRemainingSeconds = 0;
  final ValueNotifier<int> _tickNotifier = ValueNotifier<int>(0);
  bool _isScreenRecording = false;
  bool _isAudioRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _audioFilePath;
  List<List<int>> _shuffledOptionIndices = [];
  List<QuizQuestion> _activeQuestions = [];
  quill.QuillController? _quillController;
  bool _isReviewingEssay = false;

  // Power-Up Engine State
  bool _isTimeFrozen = false;
  bool _isShieldActive = false;
  List<int> _eliminatedOptions = [];
  bool _isConsumingPowerUp = false;

  int _getCampaignQuestionTime(int levelMatch) {
    if (levelMatch <= 25) return 30;
    if (levelMatch <= 50) return 25;
    if (levelMatch <= 100) return 20;
    if (levelMatch <= 150) return 15;
    return 10;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stopwatch.start();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final quizService = Provider.of<QuizService>(context, listen: false);
      // Use the actual selected Exam's properties, otherwise fallback to basic defaults
      if (widget.exam != null) {
        if (widget.exam!.examType == 'campaign') {
          _timeRemainingSeconds = 999999;
          int levelMatch =
              int.tryParse(
                RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ??
                    '0',
              ) ??
              0;
          _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
        } else {
          _timeRemainingSeconds = widget.exam!.examTimerMinutes * 60;
          _questionTimeRemainingSeconds = widget.exam!.questionTimerSeconds;
        }
      } else {
        _timeRemainingSeconds = 600; // 10 min basic fallback
        _questionTimeRemainingSeconds = 0;
      }

      // Safety: If timer is 0 or less, default to 10 minutes to prevent instant close
      if (_timeRemainingSeconds <= 0) {
        _timeRemainingSeconds = 600;
      }

      // Filter questions by selected exam
      if (widget.exam != null) {
        if (widget.exam!.examType == 'essay') {
          _activeQuestions = [
            QuizQuestion(
              id: 'essay_mock_${widget.exam!.id}',
              examId: widget.exam!.id,
              question:
                  widget.exam!.description ??
                  'Please write your complete essay answer below. Be sure to review your work before submitting.',
              options: [''],
              correctAnswerIndex: 0,
              questionType: 'essay',
            ),
          ];
        } else {
          _activeQuestions = quizService.questions
              .where((q) => q.examId == widget.exam!.id)
              .toList();
        }
      } else {
        _activeQuestions = quizService.questions;
      }

      // Safety: If no questions (e.g. refreshed on /quiz)
      if (_activeQuestions.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This exam has no questions yet!')),
        );
        context.go('/');
        return;
      }

      // Start Live Session
      quizService.startSession(
        widget.studentName,
        widget.exam?.id,
        _activeQuestions.length,
      );

      // Start Heartbeat Timer
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          quizService.heartbeatSession(
            widget.studentName,
            _currentQuestionIndex,
            _selectedAnswers.length,
          );
        }
      });

      // Shuffle options for each question if enabled for this specific exam
      _shuffledOptionIndices = _activeQuestions.map((q) {
        final indices = List<int>.generate(q.options.length, (i) => i);
        if (widget.exam?.randomizeOptions ?? false) {
          indices.shuffle();
        }
        return indices;
      }).toList();

      if ((widget.exam?.preventScreenshots ?? false) && isMobilePlatform) {
        try {
          // await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        } catch (e) {
          debugPrint("Screenshot prevention not supported on this platform.");
        }
      }

      if ((widget.exam?.recordScreen ?? false) && isMobilePlatform) {
        try {
          // Screen recording removed
        } catch (e) {
          debugPrint("Screen recording not supported on this platform.");
        }
      }

      if ((widget.exam?.recordAudio ?? false) && isMobilePlatform) {
        await _startAudioRecording();
      }

      if (mounted) {
        setState(() {});
        await _loadSavedSession();

        if (widget.exam?.examType == 'essay') {
          if (_selectedAnswers.containsKey(0) &&
              _selectedAnswers[0] != null &&
              _selectedAnswers[0].toString().isNotEmpty) {
            try {
              final decodedData =
                  await compute(jsonDecode, _selectedAnswers[0].toString())
                      as List<dynamic>;
              final doc = quill.Document.fromJson(decodedData);
              _quillController = quill.QuillController(
                document: doc,
                selection: const TextSelection.collapsed(offset: 0),
              );
            } catch (e) {
              final doc = quill.Document()
                ..insert(0, _selectedAnswers[0].toString());
              _quillController = quill.QuillController(
                document: doc,
                selection: const TextSelection.collapsed(offset: 0),
              );
            }
          } else {
            _quillController = quill.QuillController.basic();
          }

          _quillController?.document.changes.listen((_) {
            _selectedAnswers[_currentQuestionIndex] = jsonEncode(
              _quillController!.document.toDelta().toJson(),
            );
          });

          // Force collapse any text selection boundaries to prevent Arabic Action Bar copying
          _quillController?.addListener(() {
            final sel = _quillController!.selection;
            if (sel.baseOffset != sel.extentOffset) {
              _quillController!.updateSelection(
                TextSelection.collapsed(offset: sel.extentOffset),
                quill.ChangeSource.local,
              );
            }
          });
          setState(() {});
        }

        _startTimer();
        _startAutoSave();
      }
    });
  }

  Future<void> _loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('quiz_student_name');
    if (savedName == widget.studentName) {
      final savedIndex = prefs.getInt('quiz_current_index') ?? 0;
      final savedScore = prefs.getInt('quiz_score') ?? 0;
      final savedTime = prefs.getInt('quiz_time_remaining');
      final savedAnswersStr = prefs.getString('quiz_selected_answers');

      Map<int, dynamic>? parsedAnswers;
      if (savedAnswersStr != null) {
        try {
          final decoded = await compute(_decodeMap, savedAnswersStr);
          parsedAnswers = decoded.map(
            (key, value) => MapEntry(int.parse(key), value),
          );
        } catch (e) {
          debugPrint('Failed to load selected answers: $e');
        }
      }

      setState(() {
        _currentQuestionIndex = savedIndex;
        _score = savedScore;
        if (parsedAnswers != null) _selectedAnswers = parsedAnswers;
        if (savedTime != null) _timeRemainingSeconds = savedTime;
      });
      debugPrint('Loaded saved quiz session for ${widget.studentName}');
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName =
            'audio_exam_${widget.studentName}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        _audioFilePath = '${directory.path}${Platform.pathSeparator}$fileName';

        await _audioRecorder.start(const RecordConfig(), path: _audioFilePath!);
        if (mounted) {
          setState(() {
            _isAudioRecording = true;
          });
        }
        debugPrint('Audio recording started: $_audioFilePath');
      } else {
        debugPrint('Microphone permission denied');
      }
    } catch (e) {
      debugPrint('Error starting audio recording: $e');
    }
  }

  void _startAutoSave() {
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('quiz_student_name', widget.studentName);
      await prefs.setInt('quiz_current_index', _currentQuestionIndex);
      await prefs.setInt('quiz_score', _score);
      await prefs.setInt('quiz_time_remaining', _timeRemainingSeconds);

      final answersMap = _selectedAnswers.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final answersStr = await compute(jsonEncode, answersMap);
      await prefs.setString('quiz_selected_answers', answersStr);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (widget.exam?.strictAppFocus ?? false) {
        final quizService = Provider.of<QuizService>(context, listen: false);
        _timer?.cancel();
        _submitQuiz(
          _activeQuestions,
          cheatFlag: "App Focus Lost (Switched Apps)",
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemainingSeconds > 0) {
        _timeRemainingSeconds--;
      } else {
        _timer?.cancel();
        _submitQuiz(_activeQuestions);
        return;
      }

      if (_questionTimeRemainingSeconds > 0) {
        if (!_isTimeFrozen) {
          _questionTimeRemainingSeconds--;
        }
        if (_questionTimeRemainingSeconds == 0) {
          _forceNextQuestion();
        }
      }

      if (mounted) {
        _tickNotifier.value++;
      }
    });
  }

  void _forceNextQuestion() {
    // Record timeout as a failure if not answered
    if (!_selectedAnswers.containsKey(_currentQuestionIndex)) {
      _selectedAnswers[_currentQuestionIndex] = -1; // timed out marker
      _answerTimes[_currentQuestionIndex] = 0;

      // Manually trigger the score recalculation to show combo break
      _recalculateScore(
        Provider.of<QuizService>(context, listen: false).questions,
      );
    }

    if (_currentQuestionIndex < _activeQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        if (widget.exam?.examType == 'campaign') {
          int levelMatch =
              int.tryParse(
                RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ??
                    '0',
              ) ??
              0;
          _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
        } else {
          _questionTimeRemainingSeconds =
              widget.exam?.questionTimerSeconds ?? 0;
        }
        _eliminatedOptions.clear(); // Reset 50/50 chops for next question
        _isTimeFrozen = false; // Reset freeze
      });
    } else {
      _submitQuiz(_activeQuestions);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // if (_isScreenRecording && isMobilePlatform) {
    //   FlutterScreenRecording.stopRecordScreen;
    // }
    if (_isAudioRecording && isMobilePlatform) {
      _audioRecorder.stop();
    }
    if (isMobilePlatform) {
      _audioRecorder.dispose();
    }

    // Attempt to remove secure flag (mobile only)
    if (isMobilePlatform) {
      try {
        // FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (e) {
        debugPrint('Error clearing secure flags: $e');
      }
    }

    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    _quillController?.dispose();
    super.dispose();
  }

  void _submitQuiz(List<QuizQuestion> questions, {String? cheatFlag}) async {
    _stopwatch.stop();
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    // Capture context-dependent objects before async gap
    final quizService = mounted
        ? Provider.of<QuizService>(context, listen: false)
        : null;
    final router = mounted ? GoRouter.of(context) : null;

    // if (_isScreenRecording && isMobilePlatform) {
    //   await FlutterScreenRecording.stopRecordScreen;
    // }

    if (_isAudioRecording && isMobilePlatform) {
      await _audioRecorder.stop();
    }

    // Explicitly guarantee final Quill stroke payloads are fetched right before submission
    if (widget.exam?.examType == 'essay' && _quillController != null) {
      if (!_selectedAnswers.containsKey(0) ||
          _selectedAnswers[0] == null ||
          _selectedAnswers[0].toString().isEmpty) {
        _selectedAnswers[0] = jsonEncode(
          _quillController!.document.toDelta().toJson(),
        );
      }
      // Re-fetch universally ensuring the most recent keystroke is securely forwarded
      _selectedAnswers[0] = jsonEncode(
        _quillController!.document.toDelta().toJson(),
      );
    }

    Map<String, dynamic> answersJson = {};
    if (_activeQuestions.isEmpty && widget.exam?.examType == 'essay') {
      if (_selectedAnswers.containsKey(0)) {
        answersJson['0'] = _selectedAnswers[0];
      }
    } else {
      for (int i = 0; i < _activeQuestions.length; i++) {
        String dbQuestionId = _activeQuestions[i].id.toString();
        if (_selectedAnswers.containsKey(i)) {
          var val = _selectedAnswers[i];
          if (val is int && widget.exam?.examType != 'essay') {
            answersJson[dbQuestionId] = _shuffledOptionIndices[i][val];
          } else {
            answersJson[dbQuestionId] = val;
          }
        }
      }
    }

    int calculatedStars = 0;
    if (widget.exam?.examType == 'campaign' && questions.isNotEmpty) {
      double accuracyRate = _score / questions.length;
      int levelMatch =
          int.tryParse(
            RegExp(r'\d+').firstMatch(widget.exam?.title ?? '')?.group(0) ??
                '0',
          ) ??
          0;

      if (accuracyRate >= 0.90) {
        calculatedStars = 3;
      } else if (accuracyRate >= 0.75) {
        calculatedStars = 2;
      } else {
        double passRate = levelMatch > 50 ? 0.60 : 0.50; // Adaptive difficulty
        if (accuracyRate >= passRate) {
          calculatedStars = 1;
        } else {
          calculatedStars = 0;
        }
      }
    }

    final result = QuizResult(
      studentName: widget.studentName,
      examId: widget.exam?.id,
      examType: widget.exam?.examType,
      totalQuestions: widget.exam?.examType == 'essay' ? 1 : questions.length,
      correctAnswers: _score,
      timeTaken: _stopwatch.elapsed,
      gpsLocation: widget.entryGpsLocation,
      cheatFlag: cheatFlag,
      answersJson: answersJson,
      campaignScore: _totalCampaignPoints,
      earnedStars: calculatedStars,
    );

    // Clear saved session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_student_name');
    await prefs.remove('quiz_current_index');
    await prefs.remove('quiz_score');
    await prefs.remove('quiz_time_remaining');
    await prefs.remove('quiz_selected_answers');

    if (!mounted) return;
    // Submit result to backend via QuizService
    quizService?.submitResult(result);

    router?.go(
      '/results',
      extra: {
        'result': result,
        'questions': questions,
        'selectedAnswers': _selectedAnswers,
        'allowReview': widget.exam?.allowReview ?? false,
        'isEssay': widget.exam?.examType == 'essay',
        'exam': widget.exam,
      },
    );
  }

  void _answerQuestion(
    dynamic originalSelectedIndex,
    List<QuizQuestion> questions, {
    bool autoAdvance = true,
  }) {
    _selectedAnswers[_currentQuestionIndex] = originalSelectedIndex;
    if (!_answerTimes.containsKey(_currentQuestionIndex)) {
      _answerTimes[_currentQuestionIndex] = _questionTimeRemainingSeconds;
    }

    _recalculateScore(questions);

    final quizService = Provider.of<QuizService>(context, listen: false);

    // #18: Immediate feedback (disabled for new UI)
    if (autoAdvance) {
      _advanceAfterAnswer(questions, quizService);
    } else {
      setState(() {});
    }
  }

  void _recalculateScore(List<QuizQuestion> questions) {
    _score = 0;
    int points = 0;
    int combo = 0;

    final answeredIndices = _selectedAnswers.keys.toList()..sort();
    int levelMatch =
        int.tryParse(
          RegExp(r'\d+').firstMatch(widget.exam?.title ?? '')?.group(0) ?? '0',
        ) ??
        0;

    for (int index in answeredIndices) {
      final selectedOpt = _selectedAnswers[index];
      if (index >= questions.length) continue;

      final q = questions[index];
      final timeRemaining = _answerTimes[index] ?? 0;

      bool isCorrect = false;
      if (selectedOpt != -1) {
        // -1 means timed out
        if (q.questionType == 'short_answer') {
          isCorrect =
              (selectedOpt.toString().trim().toLowerCase() ==
              q.options[0].trim().toLowerCase());
        } else {
          isCorrect = (selectedOpt == q.correctAnswerIndex);
        }
      }

      if (isCorrect) {
        _score++;
        combo++;
        double multiplier = 1.0;

        if (widget.exam?.examType == 'campaign' && levelMatch <= 25) {
          // 🤩 High-Reward Early Game Boost
          if (combo >= 5)
            multiplier = 3.0;
          else if (combo >= 2)
            multiplier = 1.5;
        } else {
          // ⚔️ Standard / Hardcore Rules
          if (combo >= 5)
            multiplier = 2.0;
          else if (combo >= 2)
            multiplier = 1.2;
        }

        int basePoints = 100;
        double timeBonus = timeRemaining * 10;
        if (multiplier >= 2.0) timeBonus *= multiplier;

        points += ((basePoints * multiplier) + timeBonus).toInt();
        if (_isShieldActive && index == answeredIndices.last) {
          // 🛡️ Shield Shattered! Combo Preserved!
          _isShieldActive = false;
        } else {
          combo = 0;
          if (widget.exam?.examType == 'campaign' && levelMatch > 50) {
            points -= 50; // Hardcore penalty kicks in automatically!
          }
        }
      }
    }

    setState(() {
      _totalCampaignPoints = points;
      _currentCombo = combo;
    });
  }

  void _advanceAfterAnswer(
    List<QuizQuestion> questions,
    QuizService quizService,
  ) {
    if (widget.exam?.allowBacktracking ?? false) {
      setState(() {});
    } else {
      if (_currentQuestionIndex < questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          if (widget.exam?.examType == 'campaign') {
            int levelMatch =
                int.tryParse(
                  RegExp(
                        r'\d+',
                      ).firstMatch(widget.exam!.title ?? '')?.group(0) ??
                      '0',
                ) ??
                0;
            _questionTimeRemainingSeconds = _getCampaignQuestionTime(
              levelMatch,
            );
          } else {
            _questionTimeRemainingSeconds =
                widget.exam?.questionTimerSeconds ?? 0;
          }
          _eliminatedOptions.clear();
          _isTimeFrozen = false;
        });
      } else {
        _submitQuiz(questions);
      }
    }
  }

  void _navigateToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
    Navigator.of(context).pop(); // close drawer
  }

  // #12: Confirmation dialog before submitting
  void _confirmSubmit(List<QuizQuestion> questions) {
    final l10n = AppLocalizations.of(context)!;
    final unanswered = questions.length - _selectedAnswers.length;

    AwesomeDialog(
      context: context,
      dialogType: unanswered > 0 ? DialogType.warning : DialogType.info,
      animType: AnimType.bottomSlide,
      title: l10n.localeName == 'ar' ? 'تأكيد التسليم' : 'Confirm Submission',
      desc:
          (l10n.localeName == 'ar'
              ? 'أجبت على ${_selectedAnswers.length} من ${questions.length} سؤال.\n'
              : 'You answered ${_selectedAnswers.length} of ${questions.length} questions.\n') +
          (unanswered > 0
              ? (l10n.localeName == 'ar'
                    ? '⚠️ لديك $unanswered سؤال بدون إجابة!'
                    : '⚠️ You have $unanswered unanswered questions!')
              : (l10n.localeName == 'ar'
                    ? 'هل أنت متأكد من تسليم الامتحان؟'
                    : 'Are you sure you want to submit?')),
      btnCancelOnPress: () {},
      btnCancelText: l10n.localeName == 'ar' ? 'رجوع' : 'Go Back',
      btnOkOnPress: () => _submitQuiz(questions),
      btnOkText: l10n.localeName == 'ar' ? 'تسليم' : 'Submit',
      btnOkColor: Colors.green,
    ).show();
  }

  void _confirmWithdrawal(List<QuizQuestion> questions) {
    final l10n = AppLocalizations.of(context)!;

    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.bottomSlide,
      title: l10n.localeName == 'ar'
          ? 'انسحاب من الواجب'
          : 'Withdraw from Homework',
      desc: l10n.localeName == 'ar'
          ? 'الخروج الآن يعني الانسحاب من الواجب وفقدان فرصة المشاركة فيه نهائياً. سيتم إغلاق الواجب. هل أنت متأكد؟'
          : 'Exiting now means withdrawing from the homework and losing the chance to participate. The homework will be locked. Are you sure?',
      btnCancelOnPress: () {},
      btnCancelText: l10n.localeName == 'ar' ? 'إلغاء' : 'Cancel',
      btnOkOnPress: () => _withdrawQuiz(questions),
      btnOkText: l10n.localeName == 'ar' ? 'نعم، انسحاب' : 'Yes, Withdraw',
      btnOkColor: Colors.red,
    ).show();
  }

  void _withdrawQuiz(List<QuizQuestion> questions) async {
    _stopwatch.stop();
    _timer?.cancel();
    _autoSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    final quizService = mounted
        ? Provider.of<QuizService>(context, listen: false)
        : null;
    final router = mounted ? GoRouter.of(context) : null;

    // if (_isScreenRecording && isMobilePlatform) await FlutterScreenRecording.stopRecordScreen;
    if (_isAudioRecording && isMobilePlatform) await _audioRecorder.stop();

    // Force a blank payload ensuring backend accepts submission unconditionally
    if (_selectedAnswers.isEmpty) {
      _selectedAnswers[0] = "Withdrawn";
    }

    Map<String, dynamic> answersJson = {};
    if (_activeQuestions.isEmpty && widget.exam?.examType == 'essay') {
      if (_selectedAnswers.containsKey(0)) {
        answersJson['0'] = _selectedAnswers[0];
      }
    } else {
      for (int i = 0; i < _activeQuestions.length; i++) {
        String dbQuestionId = _activeQuestions[i].id.toString();
        if (_selectedAnswers.containsKey(i)) {
          var val = _selectedAnswers[i];
          if (val is int && widget.exam?.examType != 'essay') {
            answersJson[dbQuestionId] = _shuffledOptionIndices[i][val];
          } else {
            answersJson[dbQuestionId] = val;
          }
        }
      }
    }

    final result = QuizResult(
      studentName: widget.studentName,
      examId: widget.exam?.id,
      examType: widget.exam?.examType,
      totalQuestions: widget.exam?.examType == 'essay' ? 1 : questions.length,
      correctAnswers: 0,
      timeTaken: _stopwatch.elapsed,
      gpsLocation: widget.entryGpsLocation,
      cheatFlag: 'Withdrew',
      answersJson: answersJson,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_student_name');
    await prefs.remove('quiz_current_index');
    await prefs.remove('quiz_score');
    await prefs.remove('quiz_time_remaining');
    await prefs.remove('quiz_selected_answers');

    if (!mounted) return;
    await quizService?.submitResult(result);

    // Bypass ResultsScreen navigating natively to dashboard immediately completing the gray-out
    router?.go('/dashboard');
  }

  Future<void> _activatePowerUp(String itemKey) async {
    if (_isConsumingPowerUp) return;
    final quizService = Provider.of<QuizService>(context, listen: false);
    final inventoryCount = quizService.currentStudent?.inventory[itemKey] ?? 0;
    if (inventoryCount <= 0) return;

    setState(() => _isConsumingPowerUp = true);

    try {
      final success = await quizService.consumeStoreItem(itemKey);
      if (success && mounted) {
        setState(() {
          if (itemKey == 'time_freeze') {
            _isTimeFrozen = true;
            Future.delayed(const Duration(seconds: 15), () {
              if (mounted) setState(() => _isTimeFrozen = false);
            });
          } else if (itemKey == '50_50_chop') {
            final q = _activeQuestions[_currentQuestionIndex];
            final correctIdx = q.correctAnswerIndex;
            final otherIndices = _shuffledOptionIndices[_currentQuestionIndex]
                .where((i) => i != correctIdx)
                .toList();
            otherIndices.shuffle();
            if (otherIndices.length >= 2) {
              _eliminatedOptions.add(otherIndices[0]);
              _eliminatedOptions.add(otherIndices[1]);
            } else if (otherIndices.length == 1) {
              _eliminatedOptions.add(otherIndices[0]);
            }
          } else if (itemKey == 'combo_shield') {
            _isShieldActive = true;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isConsumingPowerUp = false);
    }
  }

  Widget _buildPowerUpTray() {
    final student = Provider.of<QuizService>(context).currentStudent;
    if (widget.exam?.examType != 'campaign' || student == null)
      return const SizedBox.shrink();

    final inventory = student.inventory;
    if (inventory.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPowerUpButton(
            'Time Freeze',
            '⌛',
            inventory['time_freeze'] ?? 0,
            'time_freeze',
            _isTimeFrozen,
          ),
          _buildPowerUpButton(
            '50/50 Chop',
            '✂️',
            inventory['50_50_chop'] ?? 0,
            '50_50_chop',
            _eliminatedOptions.isNotEmpty,
          ),
          _buildPowerUpButton(
            'Combo Shield',
            '🛡️',
            inventory['combo_shield'] ?? 0,
            'combo_shield',
            _isShieldActive,
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton(
    String name,
    String icon,
    int count,
    String key,
    bool isActive,
  ) {
    if (count <= 0 && !isActive) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => (count > 0 && !isActive) ? _activatePowerUp(key) : null,
      child: Opacity(
        opacity: (isActive || count <= 0) ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withValues(alpha: 0.3)
                : Colors.deepPurple.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.greenAccent
                  : Colors.amberAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizService = Provider.of<QuizService>(context);
    final questions = _activeQuestions;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (questions.isEmpty || _shuffledOptionIndices.isEmpty) {
      return QuizLoadingState(exam: widget.exam);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            QuizMainContent(
              exam: widget.exam,
              isReviewingEssay: _isReviewingEssay,
              currentQuestionIndex: _currentQuestionIndex,
              questions: questions,
              tickNotifier: _tickNotifier,
              questionTimeRemainingSeconds: _questionTimeRemainingSeconds,
              getCampaignQuestionTime: _getCampaignQuestionTime,
              quillController: _quillController,
              buildPowerUpTray: _buildPowerUpTray,
              selectedAnswers: _selectedAnswers,
              shuffledOptionIndices: _shuffledOptionIndices,
              eliminatedOptions: _eliminatedOptions,
              onAnswerQuestion: _answerQuestion,
            ),
            QuizTopHeader(
              exam: widget.exam,
              tickNotifier: _tickNotifier,
              timeRemainingSeconds: _timeRemainingSeconds,
              isReviewingEssay: _isReviewingEssay,
              quillController: _quillController,
              questions: questions,
              onConfirmSubmit: _confirmSubmit,
              onConfirmWithdrawal: _confirmWithdrawal,
              onReviewEssay: () {
                setState(() {
                  _isReviewingEssay = true;
                  _quillController?.readOnly = true;
                });
              },
            ),
            QuizBottomNavigation(
              exam: widget.exam,
              isReviewingEssay: _isReviewingEssay,
              currentQuestionIndex: _currentQuestionIndex,
              questions: questions,
              onEditEssay: () {
                setState(() {
                  _isReviewingEssay = false;
                  _quillController?.readOnly = false;
                });
              },
              onPrevious: () => setState(() {
                _currentQuestionIndex--;
                if (widget.exam?.examType == 'campaign') {
                  int levelMatch =
                      int.tryParse(
                        RegExp(
                              r'\d+',
                            ).firstMatch(widget.exam!.title ?? '')?.group(0) ??
                            '0',
                      ) ??
                      0;
                  _questionTimeRemainingSeconds = _getCampaignQuestionTime(
                    levelMatch,
                  );
                } else {
                  _questionTimeRemainingSeconds =
                      widget.exam?.questionTimerSeconds ?? 0;
                }
              }),
              onNext: () => setState(() {
                _currentQuestionIndex++;
                if (widget.exam?.examType == 'campaign') {
                  int levelMatch =
                      int.tryParse(
                        RegExp(
                              r'\d+',
                            ).firstMatch(widget.exam!.title ?? '')?.group(0) ??
                            '0',
                      ) ??
                      0;
                  _questionTimeRemainingSeconds = _getCampaignQuestionTime(
                    levelMatch,
                  );
                } else {
                  _questionTimeRemainingSeconds =
                      widget.exam?.questionTimerSeconds ?? 0;
                }
              }),
              onSubmit: () => _confirmSubmit(questions),
            ),
          ],
        ),
      ),
      endDrawer: (widget.exam?.allowBacktracking ?? false)
          ? _buildNavigationDrawer(questions, l10n)
          : null,
    );
  }

  Widget _buildNavigationDrawer(
    List<QuizQuestion> questions,
    AppLocalizations l10n,
  ) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.questionNavigation,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  bool isAnswered = _selectedAnswers.containsKey(index);
                  bool isCurrent = _currentQuestionIndex == index;

                  Color bgColor = Colors.white;
                  Color textColor = Colors.black87;
                  Color borderColor = Colors.grey[300]!;

                  if (isCurrent) {
                    bgColor = Theme.of(context).primaryColor;
                    textColor = Colors.white;
                    borderColor = Theme.of(context).primaryColor;
                  } else if (isAnswered) {
                    bgColor = Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.2);
                    borderColor = Theme.of(context).primaryColor;
                  }

                  return InkWell(
                    onTap: () => _navigateToQuestion(index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        border: Border.all(color: borderColor, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // close drawer
                  _submitQuiz(questions);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  l10n.localeName == 'ar' ? 'إنهاء وتسليم' : 'Submit Exam',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                l10n.localeName == 'ar'
                    ? '${_selectedAnswers.length}/${questions.length} تم الإجابة'
                    : '${_selectedAnswers.length}/${questions.length} answered',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
