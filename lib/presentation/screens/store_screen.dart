import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_quiz_app/l10n/app_localizations.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/quiz_service_facade.dart';
import '../../domain/entities/store_item.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  List<StoreItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final svc = Provider.of<QuizService>(context, listen: false);
    final items = await svc.getStoreItems();
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _showPurchaseConfirm(StoreItem item) {
    final l10n = AppLocalizations.of(context)!;
    final svc = Provider.of<QuizService>(context, listen: false);
    final student = svc.currentStudent;
    final hasEnoughPoints = (student?.points ?? 0) >= item.costPoints;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.icon,
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.coins, color: Colors.amberAccent, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${item.costPoints}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: hasEnoughPoints ? Colors.amberAccent : Colors.redAccent,
                    ),
                  ),
                ],
              ),
              if (!hasEnoughPoints) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.localeName == 'ar' ? 'نقاط غير كافية' : 'Insufficient Points',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasEnoughPoints ? Colors.amber.shade700 : Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: hasEnoughPoints
                      ? () async {
                          Navigator.pop(context);
                          final success = await svc.buyStoreItem(item.itemKey);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(success 
                                  ? (l10n.localeName == 'ar' ? 'تم الشراء بنجاح!' : 'Purchase successful!')
                                  : (l10n.localeName == 'ar' ? 'فشل الشراء' : 'Purchase failed')),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        }
                      : null,
                  child: Text(
                    l10n.localeName == 'ar' ? 'تأكيد الشراء' : 'Confirm Purchase',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = Provider.of<QuizService>(context).currentStudent;

    return Scaffold(
      backgroundColor: const Color(0xFF01001A),
      appBar: AppBar(
        title: Text(l10n.localeName == 'ar' ? 'متجر القدرات' : 'Power-Up Store'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.black45,
              border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.coins, color: Colors.amberAccent, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${student?.points ?? 0}',
                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final inventoryCount = student?.inventory[item.itemKey] ?? 0;

                return GestureDetector(
                  onTap: () => _showPurchaseConfirm(item),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.deepPurple.shade900, Colors.black87],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.deepPurple.shade300.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(item.icon, style: const TextStyle(fontSize: 48)),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(LucideIcons.coins, color: Colors.amberAccent, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${item.costPoints}',
                                      style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (inventoryCount > 0)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$inventoryCount',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
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
