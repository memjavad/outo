class StoreItem {
  final int id;
  final String name;
  final String description;
  final int costPoints;
  final String itemKey;
  final String icon;

  StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.costPoints,
    required this.itemKey,
    required this.icon,
  });

  factory StoreItem.fromJson(Map<String, dynamic> json) {
    return StoreItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      costPoints: int.tryParse(json['cost_points']?.toString() ?? '0') ?? 0,
      itemKey: json['item_key'] ?? '',
      icon: json['icon'] ?? '🎁',
    );
  }
}
