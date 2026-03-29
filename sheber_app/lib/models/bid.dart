class Bid {
  final int id;
  final int orderId;
  final int masterId;
  final String masterName;
  final String? masterAvatarUrl;
  final String masterAvatarColor;
  final bool isVerified;
  final int amount;
  final String status; // pending, accepted, rejected
  final String createdAt;

  const Bid({
    required this.id,
    required this.orderId,
    required this.masterId,
    required this.masterName,
    this.masterAvatarUrl,
    required this.masterAvatarColor,
    required this.isVerified,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) => Bid(
        id: _toInt(json['id']),
        orderId: _toInt(json['order_id']),
        masterId: _toInt(json['master_id']),
        masterName: json['master_name']?.toString() ?? '',
        masterAvatarUrl: json['master_avatar_url']?.toString(),
        masterAvatarColor: json['master_avatar_color']?.toString() ?? '#1cb7ff',
        isVerified: _toInt(json['is_verified']) == 1,
        amount: _toInt(json['amount']),
        status: json['status']?.toString() ?? 'pending',
        createdAt: json['created_at']?.toString() ?? '',
      );

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }
}
