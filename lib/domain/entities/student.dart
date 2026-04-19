class Student {
  final String id;
  final String name;
  final String phone;
  final String? bio;
  final String? profileImage;
  final String? accessCode;
  final int points;
  final int totalXp;
  final int stars;
  final Map<String, int> inventory;

  Student({
    required this.id,
    required this.name,
    required this.phone,
    this.bio,
    this.profileImage,
    this.accessCode,
    this.points = 0,
    this.totalXp = 0,
    this.stars = 0,
    this.inventory = const {},
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      phone: json['phone'] ?? json['email'] ?? '',
      bio: json['bio'],
      profileImage: json['profile_image'] ?? json['profileImage'],
      accessCode: json['access_code']?.toString(),
      points: int.tryParse(json['points']?.toString() ?? '0') ?? 0,
      totalXp: int.tryParse(json['total_xp']?.toString() ?? '0') ?? 0,
      stars: int.tryParse(json['stars']?.toString() ?? '0') ?? 0,
      inventory: json['inventory'] != null 
          ? Map<String, int>.from(json['inventory']) 
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'bio': bio,
      'profile_image': profileImage,
      'access_code': accessCode,
      'points': points,
      'total_xp': totalXp,
      'stars': stars,
      'inventory': inventory,
    };
  }
}
