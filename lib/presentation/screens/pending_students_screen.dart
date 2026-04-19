import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/entities.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

class PendingStudentsScreen extends StatefulWidget {
  const PendingStudentsScreen({super.key});

  @override
  State<PendingStudentsScreen> createState() => _PendingStudentsScreenState();
}

class _PendingStudentsScreenState extends State<PendingStudentsScreen> {
  List<Student> _pending = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPending();
  }

  Future<void> _loadPending() async {
    final service = Provider.of<QuizService>(context, listen: false);
    final list = await service.fetchPendingStudents();
    if (mounted) {
      setState(() {
        _pending = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _approve(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Student'),
        content: Text('Allow ${student.name} to join the platform?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Approve')),
        ],
      ),
    );

    final service = Provider.of<QuizService>(context, listen: false);
    if (confirm == true) {
      final success = await service.approveStudent(student.id);
      if (success) {
        _loadPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student approved')),
          );
        }
      }
    }
  }

  Future<void> _reject(Student student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Student'),
        content: Text('Delete ${student.name}\'s registration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    final service = Provider.of<QuizService>(context, listen: false);
    if (confirm == true) {
      final success = await service.rejectStudent(student.id);
      if (success) {
        _loadPending();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student rejected')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.localeName == 'ar' ? 'لا يوجد طلاب بانتظار الموافقة' : 'No pending registrations'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPending,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pending.length,
        itemBuilder: (context, index) {
          final student = _pending[index];
          return Card(
            child: ListTile(
              title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(student.phone),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    onPressed: () => _approve(student),
                  ),
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _reject(student),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
