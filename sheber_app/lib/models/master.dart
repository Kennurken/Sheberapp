class Master {
  final int id;
  final String name;
  final String profession;
  final String city;
  final String phone;
  final double rating;
  final int reviewsCount;
  final int experience; // years
  final String? avatarUrl;
  final String initial;
  final bool hasWhatsapp;
  final bool isVerified;

  const Master({
    required this.id,
    required this.name,
    required this.profession,
    required this.city,
    required this.phone,
    required this.rating,
    required this.reviewsCount,
    required this.experience,
    this.avatarUrl,
    required this.initial,
    this.hasWhatsapp = true,
    this.isVerified = false,
  });

  factory Master.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? 'Мастер';
    return Master(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: name,
      profession: json['profession']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reviewsCount: (json['reviews_count'] as num?)?.toInt() ?? 0,
      experience: (json['experience'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatar_url']?.toString(),
      initial: name.isNotEmpty ? name[0].toUpperCase() : 'М',
      hasWhatsapp: json['has_whatsapp'] == true || json['has_whatsapp'] == 1,
      isVerified: json['is_verified'] == 1 || json['is_verified'] == true,
    );
  }
}
