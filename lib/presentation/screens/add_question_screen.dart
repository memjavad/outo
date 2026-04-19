import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/entities.dart';
import '../providers/quiz_service_facade.dart';

class AddQuestionScreen extends StatefulWidget {
  const AddQuestionScreen({super.key});

  @override
  State<AddQuestionScreen> createState() => _AddQuestionScreenState();
}

class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _questionType = 'single';
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctAnswerIndex = 0;
  List<Exam> _exams = [];
  Exam? _selectedExam;
  bool _isLoadingExams = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    final service = Provider.of<QuizService>(context, listen: false);
    final exams = await service.fetchExams();
    if (mounted) {
      setState(() {
        _exams = exams;
        _isLoadingExams = false;
      });
    }
  }

  void _saveQuestion() {
    if (_formKey.currentState!.validate()) {
      final newQuestion = QuizQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        examId: _selectedExam?.id,
        question: _questionController.text,
        imageUrl: _imageUrlController.text.isNotEmpty ? _imageUrlController.text : null,
        questionType: _questionType,
        options: _optionControllers.map((c) => c.text).toList(),
        correctAnswerIndex: _correctAnswerIndex,
      );

      context.read<QuizService>().addQuestion(newQuestion);
      Navigator.of(context).pop();
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
        title: const Text('Add Question'),
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
                    // Pre-fill True/False to save time
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
              const Text('Options / Answer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                onPressed: _saveQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


