class Order {
  final int id;
  final int clientId;
  final int? masterId;
  final int? categoryId;
  final String description;
  final String address;
  final int price;
  final String status;
  final String? serviceTitle;
  final String? clientName;
  final String? masterName;
  final String? clientAvatarUrl;
  final String? masterAvatarUrl;
  final String clientAvatarColor;
  final String masterAvatarColor;
  final String? lastMessage;
  final String? lastMessageAt;
  final String createdAt;
  final String? acceptedAt;
  final String? completedAt;
  final List<String> photos;
  final int clientDone;
  final int masterDone;
  final int bidCount;   // how many pending bids (for master feed)
  final int? myBid;     // master's own bid amount if any
  /// Координаты объекта (клиент указал при создании заказа), для карты.
  final double? clientLat;
  final double? clientLng;

  Order({
    required this.id,
    required this.clientId,
    this.masterId,
    this.categoryId,
    required this.description,
    required this.address,
    required this.price,
    required this.status,
    this.serviceTitle,
    this.clientName,
    this.masterName,
    this.clientAvatarUrl,
    this.masterAvatarUrl,
    this.clientAvatarColor = '#1cb7ff',
    this.masterAvatarColor = '#1cb7ff',
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    this.photos = const [],
    this.clientDone = 0,
    this.masterDone = 0,
    this.bidCount = 0,
    this.myBid,
    this.clientLat,
    this.clientLng,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    List<String> photoList = [];
    if (json['photos'] is List) {
      photoList = (json['photos'] as List).map((e) => e.toString()).toList();
    }

    return Order(
      id: _toInt(json['id']),
      clientId: _toInt(json['client_id']),
      masterId: json['master_id'] != null ? _toInt(json['master_id']) : null,
      categoryId: json['category_id'] != null ? _toInt(json['category_id']) : null,
      description: json['description']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      price: _toInt(json['price']),
      status: json['status']?.toString() ?? 'new',
      serviceTitle: json['service_title']?.toString(),
      clientName: json['client_name']?.toString(),
      masterName: json['master_name']?.toString(),
      clientAvatarUrl: json['client_avatar_url']?.toString(),
      masterAvatarUrl: json['master_avatar_url']?.toString(),
      clientAvatarColor: json['client_avatar_color']?.toString() ?? '#1cb7ff',
      masterAvatarColor: json['master_avatar_color']?.toString() ?? '#1cb7ff',
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      acceptedAt: json['accepted_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
      photos: photoList,
      clientDone: _toInt(
        json['client_done'] ?? json['clientDone'] ?? json['client_done_flag'],
      ),
      masterDone: _toInt(
        json['master_done'] ?? json['masterDone'] ?? json['master_done_flag'],
      ),
      bidCount: _toInt(json['bid_count']),
      myBid: json['my_bid'] != null ? _toInt(json['my_bid']) : null,
      clientLat: _toDouble(json['client_lat'] ?? json['clientLat']),
      clientLng: _toDouble(json['client_lng'] ?? json['clientLng']),
    );
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v.isFinite ? v : null;
    if (v is int) return v.toDouble();
    final s = v.toString().trim();
    if (s.isEmpty) return null;
    final x = double.tryParse(s);
    return (x != null && x.isFinite) ? x : null;
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v == null) return 0;
    return int.tryParse(v.toString()) ?? 0;
  }

  String get displayTitle {
    if (serviceTitle != null && serviceTitle!.isNotEmpty) return serviceTitle!;
    if (description.isEmpty) return 'Тапсырыс #$id';
    return description.length > 50 ? description.substring(0, 50) : description;
  }

  String get statusText {
    switch (status) {
      case 'new':
        return 'Жаңа';
      case 'in_progress':
        return 'Орындалуда';
      case 'completed':
        return 'Аяқталды';
      case 'cancelled':
        return 'Болдырылмады';
      default:
        return status;
    }
  }
}
