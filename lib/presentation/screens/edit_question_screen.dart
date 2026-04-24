import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/quiz_service_facade.dart';

/// #19: Edit existing question screen
class EditQuestionScreen extends StatefulWidget {
  final QuizQuestion question;

  const EditQuestionScreen({super.key, required this.question});

  @override
  State<EditQuestionScreen> createState() => _EditQuestionScreenState();
}

class _EditQuestionScreenState extends State<EditQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _imageUrlController;
  late String _questionType;
  late List<TextEditingController> _optionControllers;
  late int _correctAnswerIndex;
  bool _isSaving = false;
  List<Exam> _exams = [];
  Exam? _selectedExam;
  bool _isLoadingExams = true;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);
    _imageUrlController = TextEditingController(text: widget.question.imageUrl ?? '');
    _questionType = widget.question.questionType;
    _optionControllers = widget.question.options
        .map((opt) => TextEditingController(text: opt))
        .toList();
    // Ensure at least 4 options
    while (_optionControllers.length < 4) {
      _optionControllers.add(TextEditingController());
    }
    _correctAnswerIndex = widget.question.correctAnswerIndex;
    _loadExams();
  }

  Future<void> _loadExams() async {
    final service = Provider.of<QuizService>(context, listen: false);
    final exams = await service.fetchExams();
    if (mounted) {
      setState(() {
        _exams = exams;
        if (widget.question.examId != null) {
          try {
            _selectedExam = _exams.firstWhere((e) => e.id == widget.question.examId);
          } catch (_) {
            _selectedExam = null;
          }
        }
        _isLoadingExams = false;
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isSaving = true; });

      final updatedQuestion = QuizQuestion(
        id: widget.question.id,
        examId: _selectedExam?.id,
        question: _questionController.text,
        richText: widget.question.richText,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        questionType: _questionType,
        options: _optionControllers.map((c) => c.text).toList(),
        correctAnswerIndex: _correctAnswerIndex,
        categoryId: widget.question.categoryId,
      );

      final success = await context.read<QuizService>().updateQuestion(updatedQuestion);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      } else {
        setState(() { _isSaving = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update question'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    _imageUrlController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Question'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ExamSelector(
                isLoadingExams: _isLoadingExams,
                selectedExam: _selectedExam,
                exams: _exams,
                onChanged: (val) => setState(() => _selectedExam = val),
              ),
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Question Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a question' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),
              _QuestionTypeSelector(
                questionType: _questionType,
                onChanged: (val) {
                  setState(() {
                    _questionType = val!;
                    if (_questionType == 'true_false') {
                      _optionControllers[0].text = 'True';
                      _optionControllers[1].text = 'False';
                      _optionControllers[2].text = '';
                      _optionControllers[3].text = '';
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              const Text('Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              _OptionsBuilder(
                questionType: _questionType,
                optionControllers: _optionControllers,
                correctAnswerIndex: _correctAnswerIndex,
                onCorrectAnswerChanged: (val) => setState(() => _correctAnswerIndex = val),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class _ExamSelector extends StatelessWidget {
  final bool isLoadingExams;
  final Exam? selectedExam;
  final List<Exam> exams;
  final ValueChanged<Exam?> onChanged;

  const _ExamSelector({
    required this.isLoadingExams,
    required this.selectedExam,
    required this.exams,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingExams) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        DropdownButtonFormField<Exam?>(
          initialValue: selectedExam,
          decoration: const InputDecoration(
            labelText: 'Assign to Exam (Optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.assignment),
          ),
          items: [
            const DropdownMenuItem<Exam?>(
              value: null,
              child: Text('Global Question Bank (Unassigned)'),
            ),
            ...exams.map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e.title),
                )),
          ],
          onChanged: onChanged,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _QuestionTypeSelector extends StatelessWidget {
  final String questionType;
  final ValueChanged<String?> onChanged;

  const _QuestionTypeSelector({
    required this.questionType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: questionType,
      decoration: const InputDecoration(
        labelText: 'Question Type',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'single', child: Text('Single Choice')),
        DropdownMenuItem(value: 'multiple', child: Text('Multiple Choice (Checkboxes)')),
        DropdownMenuItem(value: 'true_false', child: Text('True / False')),
        DropdownMenuItem(value: 'short_answer', child: Text('Short Answer (Text)')),
      ],
      onChanged: onChanged,
    );
  }
}

class _OptionsBuilder extends StatelessWidget {
  final String questionType;
  final List<TextEditingController> optionControllers;
  final int correctAnswerIndex;
  final ValueChanged<int> onCorrectAnswerChanged;

  const _OptionsBuilder({
    required this.questionType,
    required this.optionControllers,
    required this.correctAnswerIndex,
    required this.onCorrectAnswerChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (questionType == 'short_answer') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Provide the EXACT text answer you expect students to type:'),
          const SizedBox(height: 8),
          TextFormField(
            controller: optionControllers[0],
            decoration: const InputDecoration(
              labelText: 'Expected Correct Answer',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Please enter the answer' : null,
          ),
        ],
      );
    } else if (questionType == 'true_false') {
      return Column(
        children: [
          for (int i = 0; i < 2; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: correctAnswerIndex,
                    onChanged: (int? value) => onCorrectAnswerChanged(value!),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: optionControllers[i],
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Option ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    } else {
      return Column(
        children: [
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: correctAnswerIndex,
                    onChanged: (int? value) => onCorrectAnswerChanged(value!),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: optionControllers[i],
                      decoration: InputDecoration(
                        labelText: 'Option ${i + 1}',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter an option' : null,
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    }
  }
}
