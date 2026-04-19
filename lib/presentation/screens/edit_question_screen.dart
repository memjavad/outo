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
              if (_isLoadingExams)
                const Center(child: CircularProgressIndicator())
              else ...[
                DropdownButtonFormField<Exam?>(
                  initialValue: _selectedExam,
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
                    ..._exams.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.title),
                        )),
                  ],
                  onChanged: (val) => setState(() => _selectedExam = val),
                ),
                const SizedBox(height: 24),
              ],
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
              DropdownButtonFormField<String>(
                initialValue: _questionType,
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
              if (_questionType == 'short_answer') ...[
                const Text('Provide the EXACT text answer you expect students to type:'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _optionControllers[0],
                  decoration: const InputDecoration(
                    labelText: 'Expected Correct Answer',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter the answer' : null,
                ),
              ] else if (_questionType == 'true_false') ...[
                for (int i = 0; i < 2; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: _correctAnswerIndex,
                          onChanged: (int? value) => setState(() => _correctAnswerIndex = value!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[i],
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
              ] else ...[
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: _correctAnswerIndex,
                          onChanged: (int? value) => setState(() => _correctAnswerIndex = value!),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _optionControllers[i],
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


