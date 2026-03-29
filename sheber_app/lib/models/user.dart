class User {
  final int id;
  final String name;
  final String role;
  final String phone;
  final String city;
  final String? avatarUrl;
  final String avatarColor;
  final String profession;
  final String bio;
  final int experience;
  final bool isNew;
  final String subscription; // 'free' | 'premium'
  final DateTime? subscriptionExpiresAt;
  final bool subscriptionIsTrial; // true when auto_renew=0 (free 30-day period)

  User({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.city = '',
    this.avatarUrl,
    this.avatarColor = '#1cb7ff',
    this.profession = '',
    this.bio = '',
    this.experience = 0,
    this.isNew = false,
    this.subscription = 'free',
    this.subscriptionExpiresAt,
    this.subscriptionIsTrial = false,
  });

  bool get isPremium =>
      subscription == 'premium' &&
      (subscriptionExpiresAt == null || subscriptionExpiresAt!.isAfter(DateTime.now()));

  int get premiumDaysLeft {
    if (!isPremium || subscriptionExpiresAt == null) return 0;
    return subscriptionExpiresAt!.difference(DateTime.now()).inDays;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? expAt;
    final expStr = json['subscription_expires_at']?.toString();
    if (expStr != null && expStr.isNotEmpty) {
      expAt = DateTime.tryParse(expStr);
    }
    return User(
      id: (json['id'] is int) ? json['id'] : int.parse(json['id'].toString()),
      name: json['name']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      phone: json['phone']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      avatarColor: json['avatar_color']?.toString() ?? '#1cb7ff',
      profession: json['profession']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      experience: (json['experience'] is int)
          ? json['experience'] as int
          : int.tryParse(json['experience']?.toString() ?? '0') ?? 0,
      isNew: json['is_new'] == true,
      subscription: json['subscription']?.toString() ?? 'free',
      subscriptionExpiresAt: expAt,
      subscriptionIsTrial: json['subscription_is_trial'] == true || json['subscription_is_trial'] == 1,
    );
  }

  User copyWith({
    String? role,
    String? name,
    String? city,
    String? profession,
    String? bio,
    int? experience,
    String? phone,
    String? avatarUrl,
    String? avatarColor,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarColor: avatarColor ?? this.avatarColor,
      profession: profession ?? this.profession,
      bio: bio ?? this.bio,
      experience: experience ?? this.experience,
      isNew: isNew,
      subscription: subscription,
      subscriptionExpiresAt: subscriptionExpiresAt,
      subscriptionIsTrial: subscriptionIsTrial,
    );
  }
}
