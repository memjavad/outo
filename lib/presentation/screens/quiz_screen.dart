import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
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

Map<String, dynamic> _decodeMap(String data) => jsonDecode(data) as Map<String, dynamic>;

class QuizScreen extends StatefulWidget {
  final String studentName;
  final String? entryGpsLocation;
  final Exam? exam;

  const QuizScreen({super.key, required this.studentName, this.entryGpsLocation, this.exam});

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
          int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ?? '0') ?? 0;
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
                question: widget.exam!.description ?? 'Please write your complete essay answer below. Be sure to review your work before submitting.',
                options: [''],
                correctAnswerIndex: 0,
                questionType: 'essay',
             )
          ];
        } else {
          _activeQuestions = quizService.questions.where((q) => q.examId == widget.exam!.id).toList();
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
      quizService.startSession(widget.studentName, widget.exam?.id, _activeQuestions.length);

      // Start Heartbeat Timer
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        if (mounted) {
          quizService.heartbeatSession(widget.studentName, _currentQuestionIndex, _selectedAnswers.length);
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
          if (_selectedAnswers.containsKey(0) && _selectedAnswers[0] != null && _selectedAnswers[0].toString().isNotEmpty) {
            try {
              final decodedData = await compute(jsonDecode, _selectedAnswers[0].toString()) as List<dynamic>;
              final doc = quill.Document.fromJson(decodedData);
              _quillController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
            } catch (e) {
              final doc = quill.Document()..insert(0, _selectedAnswers[0].toString());
              _quillController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
            }
          } else {
            _quillController = quill.QuillController.basic();
          }
          
          _quillController?.document.changes.listen((_) {
             _selectedAnswers[_currentQuestionIndex] = jsonEncode(_quillController!.document.toDelta().toJson());
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
             parsedAnswers = decoded.map((key, value) => MapEntry(int.parse(key), value));
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
        final fileName = 'audio_exam_${widget.studentName}_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
      
      final answersMap = _selectedAnswers.map((key, value) => MapEntry(key.toString(), value));
      final answersStr = await compute(jsonEncode, answersMap);
      await prefs.setString('quiz_selected_answers', answersStr);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (widget.exam?.strictAppFocus ?? false) {
        _timer?.cancel();
        _submitQuiz(_activeQuestions, cheatFlag: "App Focus Lost (Switched Apps)");
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
       _recalculateScore(Provider.of<QuizService>(context, listen: false).questions);
    }
    
    if (_currentQuestionIndex < _activeQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        if (widget.exam?.examType == 'campaign') {
          int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ?? '0') ?? 0;
          _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
        } else {
          _questionTimeRemainingSeconds = widget.exam?.questionTimerSeconds ?? 0;
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
    final quizService = mounted ? Provider.of<QuizService>(context, listen: false) : null;
    final router = mounted ? GoRouter.of(context) : null;
    
    // if (_isScreenRecording && isMobilePlatform) {
    //   await FlutterScreenRecording.stopRecordScreen;
    // }
    
    if (_isAudioRecording && isMobilePlatform) {
      await _audioRecorder.stop();
    }
    
    // Explicitly guarantee final Quill stroke payloads are fetched right before submission
    if (widget.exam?.examType == 'essay' && _quillController != null) {
      if (!_selectedAnswers.containsKey(0) || _selectedAnswers[0] == null || _selectedAnswers[0].toString().isEmpty) {
         _selectedAnswers[0] = jsonEncode(_quillController!.document.toDelta().toJson());
      }
      // Re-fetch universally ensuring the most recent keystroke is securely forwarded
      _selectedAnswers[0] = jsonEncode(_quillController!.document.toDelta().toJson());
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
       int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam?.title ?? '')?.group(0) ?? '0') ?? 0;
       
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

    router?.go('/results', extra: {
      'result': result,
      'questions': questions,
      'selectedAnswers': _selectedAnswers,
      'allowReview': widget.exam?.allowReview ?? false,
      'isEssay': widget.exam?.examType == 'essay',
      'exam': widget.exam,
    });
  }

  void _answerQuestion(dynamic originalSelectedIndex, List<QuizQuestion> questions, {bool autoAdvance = true}) {
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
    int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam?.title ?? '')?.group(0) ?? '0') ?? 0;
    
    for (int index in answeredIndices) {
      final selectedOpt = _selectedAnswers[index];
      if (index >= questions.length) continue;
      
      final q = questions[index];
      final timeRemaining = _answerTimes[index] ?? 0;
      
      bool isCorrect = false;
      if (selectedOpt != -1) { // -1 means timed out
        if (q.questionType == 'short_answer') {
           isCorrect = (selectedOpt.toString().trim().toLowerCase() == q.options[0].trim().toLowerCase());
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
             if (combo >= 5) multiplier = 3.0;
             else if (combo >= 2) multiplier = 1.5;
         } else {
             // ⚔️ Standard / Hardcore Rules
             if (combo >= 5) multiplier = 2.0;
             else if (combo >= 2) multiplier = 1.2;
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

  void _advanceAfterAnswer(List<QuizQuestion> questions, QuizService quizService) {
    if (widget.exam?.allowBacktracking ?? false) {
      setState(() {});
    } else {
      if (_currentQuestionIndex < questions.length - 1) {
        setState(() {
          _currentQuestionIndex++;
          if (widget.exam?.examType == 'campaign') {
            int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ?? '0') ?? 0;
            _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
          } else {
            _questionTimeRemainingSeconds = widget.exam?.questionTimerSeconds ?? 0;
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
      desc: (l10n.localeName == 'ar'
              ? 'أجبت على ${_selectedAnswers.length} من ${questions.length} سؤال.\n'
              : 'You answered ${_selectedAnswers.length} of ${questions.length} questions.\n') +
            (unanswered > 0
                ? (l10n.localeName == 'ar'
                    ? '⚠️ لديك $unanswered سؤال بدون إجابة!'
                    : '⚠️ You have $unanswered unanswered questions!')
                : (l10n.localeName == 'ar' ? 'هل أنت متأكد من تسليم الامتحان؟' : 'Are you sure you want to submit?')),
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
      title: l10n.localeName == 'ar' ? 'انسحاب من الواجب' : 'Withdraw from Homework',
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
    
    final quizService = mounted ? Provider.of<QuizService>(context, listen: false) : null;
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
            final otherIndices = _shuffledOptionIndices[_currentQuestionIndex].where((i) => i != correctIdx).toList();
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
    if (widget.exam?.examType != 'campaign' || student == null) return const SizedBox.shrink();

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
          _buildPowerUpButton('Time Freeze', '⌛', inventory['time_freeze'] ?? 0, 'time_freeze', _isTimeFrozen),
          _buildPowerUpButton('50/50 Chop', '✂️', inventory['50_50_chop'] ?? 0, '50_50_chop', _eliminatedOptions.isNotEmpty),
          _buildPowerUpButton('Combo Shield', '🛡️', inventory['combo_shield'] ?? 0, 'combo_shield', _isShieldActive),
        ],
      ),
    );
  }

  Widget _buildPowerUpButton(String name, String icon, int count, String key, bool isActive) {
    if (count <= 0 && !isActive) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () => (count > 0 && !isActive) ? _activatePowerUp(key) : null,
      child: Opacity(
        opacity: (isActive || count <= 0) ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.deepPurple.shade900,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isActive ? Colors.greenAccent : Colors.amberAccent.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = _activeQuestions;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (questions.isEmpty || _shuffledOptionIndices.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 80,
                color: theme.scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: theme.primaryColor,
                          style: IconButton.styleFrom(backgroundColor: theme.colorScheme.surfaceContainerHighest),
                          onPressed: () => context.pop(),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.exam?.examType == 'essay' 
                              ? (l10n.localeName == 'ar' ? 'بوابة الواجبات' : 'Essay Homework') 
                              : 'Examination Portal',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor, fontFamily: theme.textTheme.displayLarge?.fontFamily),
                        ),
                      ],
                    ),
                    // End placeholder
                    const SizedBox.shrink(),
                  ],
                ),
              ),
              Expanded(
                child: Center(
          child: Skeletonizer(
            enabled: true,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loading question...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('This is a placeholder for the actual question text which is currently loading.'),
                  const SizedBox(height: 32),
                  ...List.generate(4, (index) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    height: 56,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(16)),
                  )),
                ],
              ),
            ),
          ),
        ),
              ),
            ],
          ),
        ), 
      );
    }

    final question = questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        color: theme.scaffoldBackgroundColor,
        child: Stack(
          children: [
            // --- Main Scrollable Content ---
            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: (widget.exam?.examType == 'essay' && !_isReviewingEssay) ? 120 : 80, 
                  left: (widget.exam?.examType == 'essay') ? 4 : 24, 
                  right: (widget.exam?.examType == 'essay') ? 4 : 24, 
                  bottom: 40
                ),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.exam?.examType != 'essay') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.localeName == 'ar' ? 'التقدم' : 'PROGRESS', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      text: '${l10n.question} ${_currentQuestionIndex + 1} ',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.primaryColor),
                      children: [
                        TextSpan(
                          text: l10n.ofTotal(questions.length).replaceFirst('of ', 'of ').replaceFirst('من ', 'من '),
                          style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  progressIndicatorTheme: Theme.of(context).progressIndicatorTheme.copyWith(
                    color: Theme.of(context).primaryColor,
                    linearTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    circularTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ],
            
            // Asymmetric Question Layout
            if (widget.exam?.examType == 'campaign')
              ValueListenableBuilder<int>(
                valueListenable: _tickNotifier,
                builder: (context, _, child) {
                  int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam?.title ?? '')?.group(0) ?? '1') ?? 1;
                  int maxTime = _getCampaignQuestionTime(levelMatch);
                  double timeProgress = maxTime > 0 ? _questionTimeRemainingSeconds / maxTime : 0;
                  bool isUrgent = _questionTimeRemainingSeconds <= 5;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.localeName == 'ar' ? 'الوقت المتبقي' : 'TIME REMAINING',
                              style: TextStyle(
                                fontSize: 12, 
                                fontWeight: FontWeight.bold, 
                                letterSpacing: 1.5, 
                                color: isUrgent ? Colors.redAccent : theme.colorScheme.onSurfaceVariant
                              ),
                            ),
                            Text(
                              '$_questionTimeRemainingSeconds s',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: FontWeight.bold, 
                                color: isUrgent ? Colors.redAccent : theme.colorScheme.primary,
                                fontFeatures: const [FontFeature.tabularFigures()]
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
                            height: 8,
                            width: double.infinity,
                            alignment: AlignmentDirectional.centerStart,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                            child: FractionallySizedBox(
                              widthFactor: timeProgress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isUrgent 
                                        ? [Colors.redAccent, Colors.orangeAccent] 
                                        : [Colors.amberAccent, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isUrgent ? Colors.redAccent : Colors.orange).withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    )
                                  ]
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.directional(
                  textDirection: Directionality.of(context),
                  start: -16,
                  top: 0,
                  child: Container(
                    width: 4,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 8.0),
                  child: Text(
                    question.question,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, height: 1.5),
                  ),
                ),
              ],
            ),
            if (question.richText != null && question.richText!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.04), 
                      blurRadius: 30, 
                      offset: const Offset(0, 4)
                    )
                  ]
                ),
                child: MarkdownBody(
                  data: question.richText!,
                  selectable: false,
                  styleSheet: MarkdownStyleSheet(
                    p: TextStyle(fontSize: 16, height: 1.5, color: Theme.of(context).textTheme.bodyLarge?.color),
                    code: TextStyle(backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest, fontFamily: 'monospace'),
                    codeblockDecoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
            if (question.imageUrl != null && question.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  question.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              ),
            ],
            const SizedBox(height: 40),
            
            if (question.questionType == 'short_answer' || question.questionType == 'essay') ...[
              if (question.questionType != 'essay')
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                  child: Text(
                    l10n.localeName == 'ar' ? 'إجابتك' : 'YOUR RESPONSE', 
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: theme.colorScheme.onSurfaceVariant)
                  ),
                ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: question.questionType == 'essay' ? 8 : 0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(question.questionType == 'essay' ? 8 : 16),
                  border: question.questionType == 'essay' 
                      ? Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3), width: 1.0) 
                      : null,
                  boxShadow: [
                    if (question.questionType == 'essay')
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 8), spreadRadius: 0)
                    else
                      BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.04), blurRadius: 40, offset: const Offset(0, 10))
                  ]
                ),
                child: question.questionType == 'essay' && _quillController != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
                          constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.70),
                          child: quill.QuillEditor.basic(
                            controller: _quillController!,
                            config: quill.QuillEditorConfig(
                              contextMenuBuilder: (context, rawEditorState) {
                                return const SizedBox.shrink();
                              },
                              customStyles: quill.DefaultStyles(
                                paragraph: quill.DefaultTextBlockStyle(
                                  TextStyle(fontSize: 16, height: 1.8, color: theme.colorScheme.onSurface),
                                  const quill.HorizontalSpacing(0, 0),
                                  const quill.VerticalSpacing(0, 0),
                                  const quill.VerticalSpacing(0, 0),
                                  null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : TextFormField(
                      initialValue: _selectedAnswers[_currentQuestionIndex]?.toString() ?? '',
                      onChanged: (val) => _answerQuestion(val, questions, autoAdvance: false),
                      maxLines: null,
                      minLines: question.questionType == 'essay' ? 15 : 1,
                      keyboardType: question.questionType == 'essay' ? TextInputType.multiline : TextInputType.text,
                      textInputAction: question.questionType == 'essay' ? TextInputAction.newline : TextInputAction.done,
                      style: question.questionType == 'essay' ? TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: theme.colorScheme.onSurface,
                      ) : null,
                      decoration: InputDecoration(
                        hintText: question.questionType == 'essay' ? l10n.essayHint : l10n.typeAnswerHere,
                        hintStyle: question.questionType == 'essay' ? TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5), height: 1.8) : null,
                        filled: question.questionType != 'essay',
                        fillColor: question.questionType == 'essay' ? Colors.transparent : theme.colorScheme.surfaceContainerHighest,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.all(24),
                      ),
                    ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedAnswers.containsKey(_currentQuestionIndex) 
                          ? 'AUTOSAVED AT ${TimeOfDay.now().format(context).toUpperCase()}' 
                          : '', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))
                    ),
                    Text(
                      'WORD COUNT: ${(_selectedAnswers[_currentQuestionIndex]?.toString() ?? '').split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length}', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6))
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildPowerUpTray(),
              ...List.generate(
                question.questionType == 'true_false' ? 2 : question.options.length,
                (index) {
                  final originalIndex = _shuffledOptionIndices[_currentQuestionIndex][index];
                  final isSelected = _selectedAnswers[_currentQuestionIndex] == originalIndex;
                  final isEliminated = _eliminatedOptions.contains(originalIndex);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Semantics(
                      button: true,
                      label: question.options[originalIndex],
                      selected: isSelected,
                      child: IgnorePointer(
                        ignoring: isEliminated,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isEliminated ? 0.2 : 1.0,
                          child: ElevatedButton(
                            onPressed: () => _answerQuestion(originalIndex, questions),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isSelected
                                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                                : BorderSide.none,
                          ),
                          backgroundColor: isSelected
                              ? Theme.of(context).primaryColor.withOpacity(0.05)
                              : Theme.of(context).colorScheme.surfaceContainerLowest,
                          foregroundColor: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).colorScheme.onSurface,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 20),
                              ),
                            Text(
                              question.options[originalIndex],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
            const SizedBox(height: 48),
            // Ghost Icon Motif
            Center(
              child: Opacity(
                opacity: 0.05,
                child: Icon(Icons.menu_book, size: 140, color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 150),

          ], // <-- Closes children of Column
        ),
      ),
    ), // <-- Closes SafeArea
    
    // --- Fixed Top Header (Shared Component) ---
    Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerLowest,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 12,
              left: 16,
              right: 16,
            ),
            child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () {
                  if (widget.exam?.examType == 'essay') {
                    _confirmWithdrawal(questions);
                  } else {
                    _confirmSubmit(questions);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.close, color: theme.primaryColor, size: 24),
                ),
              ),
            ),
            
            // Timer Chip inside Header
            if (widget.exam?.examType != 'campaign')
               ValueListenableBuilder<int>(
              valueListenable: _tickNotifier,
              builder: (context, _, child) {
                final minutes = (_timeRemainingSeconds ~/ 60).toString().padLeft(2, '0');
                final seconds = (_timeRemainingSeconds % 60).toString().padLeft(2, '0');
                final isWarning = _timeRemainingSeconds <= 60;
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isWarning 
                        ? theme.colorScheme.errorContainer 
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule, size: 16, color: isWarning ? theme.colorScheme.error : theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        '$minutes:$seconds',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isWarning ? theme.colorScheme.error : theme.primaryColor,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            if (widget.exam?.examType != 'essay')
              TextButton(
                onPressed: () => _confirmSubmit(questions),
                style: TextButton.styleFrom(
                  foregroundColor: theme.primaryColor,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  l10n.localeName == 'ar' ? 'إنهاء' : 'End Exam', 
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: theme.textTheme.bodyMedium?.fontFamily)
                ),
              ),
            if (widget.exam?.examType == 'essay' && !_isReviewingEssay)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isReviewingEssay = true;
                    _quillController?.readOnly = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.localeName == 'ar' ? 'مراجعة' : 'REVIEW', 
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.remove_red_eye, size: 14),
                  ],
                ),
              ),
          ],
        ),
      ),
      if (widget.exam?.examType == 'essay' && !_isReviewingEssay && _quillController != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2))),
            boxShadow: [
              BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Theme(
                    data: theme.copyWith(iconTheme: theme.iconTheme.copyWith(size: 20)),
                    child: quill.QuillSimpleToolbar(
                      controller: _quillController!,
                      config: const quill.QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: false,
                        showColorButton: false,
                        showBackgroundColorButton: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showStrikeThrough: false,
                        showInlineCode: false,
                        showCodeBlock: false,
                        showSearchButton: false,
                        showLink: false,
                        showQuote: false,
                        showUndo: false,
                        showRedo: false,
                        showHeaderStyle: false,
                        showListCheck: false,
                        showClearFormat: false,
                        showIndent: false,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: AnimatedBuilder(
                  animation: _quillController!,
                  builder: (context, child) {
                    final text = _quillController!.document.toPlainText();
                    final count = text.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
                    return Text(
                      '$count W', 
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6))
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ),

  // --- Bottom Floating Navigation (Shared Component) ---
    if (widget.exam?.examType != 'essay' || _isReviewingEssay)
      Positioned(
        bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16, top: 16, left: 16, right: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(color: theme.colorScheme.primary.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, -10))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_isReviewingEssay)
                  InkWell(
                    onTap: () {
                      setState(() { 
                        _isReviewingEssay = false; 
                        _quillController?.readOnly = false;
                      });
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                          const SizedBox(width: 8),
                          Text(l10n.localeName == 'ar' ? 'تعديل الواجب' : 'EDIT ESSAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.primary.withValues(alpha: 0.8))),
                        ],
                      ),
                    ),
                  )
                else if (widget.exam?.examType != 'essay')
                  Opacity(
                    opacity: _currentQuestionIndex > 0 ? 1.0 : 0.4,
                    child: InkWell(
                      onTap: _currentQuestionIndex > 0 ? () => setState(() { 
                        _currentQuestionIndex--; 
                        if (widget.exam?.examType == 'campaign') {
                          int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ?? '0') ?? 0;
                          _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
                        } else {
                          _questionTimeRemainingSeconds = widget.exam?.questionTimerSeconds ?? 0;
                        }
                      }) : null,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                            const SizedBox(width: 8),
                            Text(l10n.localeName == 'ar' ? 'السابق' : 'PREVIOUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: theme.colorScheme.primary.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                
                ElevatedButton(
                  onPressed: () {
                      if (_currentQuestionIndex < questions.length - 1) {
                        setState(() {
                          _currentQuestionIndex++;
                          if (widget.exam?.examType == 'campaign') {
                            int levelMatch = int.tryParse(RegExp(r'\d+').firstMatch(widget.exam!.title ?? '')?.group(0) ?? '0') ?? 0;
                            _questionTimeRemainingSeconds = _getCampaignQuestionTime(levelMatch);
                          } else {
                            _questionTimeRemainingSeconds = widget.exam?.questionTimerSeconds ?? 0;
                          }
                        });
                      } else {
                        _confirmSubmit(questions);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 10,
                      shadowColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentQuestionIndex < questions.length - 1 
                              ? (l10n.localeName == 'ar' ? 'التالي' : 'SAVE & NEXT') 
                              : (_isReviewingEssay 
                                  ? (l10n.localeName == 'ar' ? 'تأكيد التسليم' : 'CONFIRM SUBMIT') 
                                  : (l10n.localeName == 'ar' ? 'تسليم' : 'SUBMIT')), 
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
          ], // <-- Closes children of Stack
        ),
      ),
      endDrawer: (widget.exam?.allowBacktracking ?? false) ? _buildNavigationDrawer(questions, l10n) : null,
    );
  }

  Widget _buildNavigationDrawer(List<QuizQuestion> questions, AppLocalizations l10n) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.questionNavigation,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    bgColor = Theme.of(context).primaryColor.withValues(alpha: 0.2);
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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





