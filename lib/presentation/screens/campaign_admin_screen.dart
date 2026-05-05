import 'package:flutter/material.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/entities.dart';

class CampaignAdminScreen extends StatefulWidget {
  const CampaignAdminScreen({super.key});

  @override
  State<CampaignAdminScreen> createState() => _CampaignAdminScreenState();
}

class _CampaignAdminScreenState extends State<CampaignAdminScreen> {
  List<Exam> _campaigns = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    final service = Provider.of<QuizService>(context, listen: false);
    final exams = await service.fetchExams();
    if (mounted) {
      setState(() {
        _campaigns = exams.where((e) => e.examType == 'campaign').toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddCampaignDialog() async {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final unlockCostController = TextEditingController(text: '0');
    String? prerequisiteExamId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Campaign Level'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Level Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: prerequisiteExamId,
                      decoration: const InputDecoration(labelText: 'Prerequisite Level', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem(value: null, child: Text("None (First Level)")),
                        ..._campaigns.map((c) => DropdownMenuItem(value: c.id, child: Text(c.title))),
                      ],
                      onChanged: (val) => setDialogState(() => prerequisiteExamId = val),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: unlockCostController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Unlock Cost (XP)', border: OutlineInputBorder()),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Create'),
                ),
              ],
            );
          }
        );
      },
    );

    if (result == true && titleController.text.isNotEmpty) {
      if (!mounted) return;
      final service = Provider.of<QuizService>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);
      int cost = int.tryParse(unlockCostController.text) ?? 0;
      
      final success = await service.addExam(
        titleController.text, 
        description: descController.text,
        examType: 'campaign',
        prerequisiteExamId: prerequisiteExamId,
        unlockCost: cost
      );
      if (success) {
        _loadCampaigns();
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Campaign level created successfully'), backgroundColor: Colors.purple));
        }
      }
    }
  }

  Future<void> _deleteCampaign(Exam exam) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Campaign Level'),
        content: Text('Delete "${exam.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
        _loadCampaigns();
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Campaign level deleted'), backgroundColor: Colors.purple));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.purple));
    }

    return Scaffold(
      body: _campaigns.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.map, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No campaign levels yet', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                  onPressed: _showAddCampaignDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Create First Level'),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadCampaigns,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campaigns.length,
              itemBuilder: (context, index) {
                final exam = _campaigns[index];
                final prerequisiteName = _campaigns.where((c) => c.id == exam.prerequisiteExamId).firstOrNull?.title ?? "None";
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple.withValues(alpha: 0.1),
                      child: const Icon(LucideIcons.mapPin, color: Colors.purple),
                    ),
                    title: Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exam.description != null && exam.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                            child: Text(exam.description!),
                          ),
                        Text('Requires: $prerequisiteName • Cost: ${exam.unlockCost} XP', style: TextStyle(color: Colors.purple.shade300, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: AppLocalizations.of(context)!.deleteCampaign,
                      onPressed: () => _deleteCampaign(exam),
                    ),
                    onTap: () {
                      // Navigate to Question Bank filtered by this exam (stretch goal)
                    },
                  ),
                );
              },
            ),
          ),
      floatingActionButton: _campaigns.isNotEmpty ? FloatingActionButton(
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        onPressed: _showAddCampaignDialog,
        tooltip: 'Create New Campaign Level',
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
