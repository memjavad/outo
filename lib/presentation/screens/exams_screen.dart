import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/entities.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  List<Exam> _exams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoading = true);
    final service = Provider.of<QuizService>(context, listen: false);
    final exams = await service.fetchExams();
    if (mounted) {
      setState(() {
        _exams = exams.where((e) => e.examType == 'standard').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddExamDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Create New Exam'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Exam Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      if (!mounted) return;
      final service = Provider.of<QuizService>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final success = await service.addExam(
        titleController.text,
        description: descController.text,
      );
      if (success) {
        _loadExams();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Exam created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteExam(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Exam'),
            content: Text('Delete "${exam.title}"? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final service = Provider.of<QuizService>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      final success = await service.deleteExam(exam.id);
      if (success) {
        _loadExams();
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Exam deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body:
          _exams.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No exams created yet',
                      style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showAddExamDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Exam'),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadExams,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _exams.length,
                  itemBuilder: (context, index) {
                    final exam = _exams[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          exam.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle:
                            exam.description != null &&
                                    exam.description!.isNotEmpty
                                ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(exam.description!),
                                )
                                : null,
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete Exam',
                          onPressed: () => _deleteExam(exam),
                        ),
                        onTap: () {
                          // Navigate to Question Bank filtered by this exam (stretch goal)
                        },
                      ),
                    );
                  },
                ),
              ),
      floatingActionButton:
          _exams.isNotEmpty
              ? FloatingActionButton(
                onPressed: _showAddExamDialog,
                tooltip: 'Create New Exam',
                child: const Icon(Icons.add),
              )
              : null,
    );
  }
}
