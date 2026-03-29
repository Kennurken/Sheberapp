/// Review model with 3-day edit window support.
class Review {
  final int     id;
  final int     orderId;
  final int     masterId;
  final int     clientId;
  final int     rating;
  final String  comment;
  final String  createdAt;
  final String? editableUntil;
  final String? updatedAt;
  final bool    canEdit;
  final int     hoursRemaining;

  const Review({
    required this.id,
    required this.orderId,
    required this.masterId,
    required this.clientId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.editableUntil,
    this.updatedAt,
    required this.canEdit,
    required this.hoursRemaining,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id             : (json['id']             as num? ?? 0).toInt(),
      orderId        : (json['order_id']        as num? ?? 0).toInt(),
      masterId       : (json['master_id']       as num? ?? 0).toInt(),
      clientId       : (json['client_id']       as num? ?? 0).toInt(),
      rating         : (json['rating']          as num? ?? 5).toInt(),
      comment        : (json['comment']         as String? ?? json['body'] as String? ?? ''),
      createdAt      : (json['created_at']      as String? ?? ''),
      editableUntil  : json['editable_until']   as String?,
      updatedAt      : json['updated_at']       as String?,
      canEdit        : json['can_edit'] == true || json['can_edit'] == 1,
      hoursRemaining : (json['hours_remaining'] as num? ?? 0).toInt(),
    );
  }

  /// Human-readable time remaining label (e.g. "2 дня", "5 часов")
  String get timeRemainingLabel {
    if (!canEdit || hoursRemaining <= 0) return '';
    if (hoursRemaining >= 48) return '${(hoursRemaining / 24).floor()} дн.';
    if (hoursRemaining >= 1)  return '$hoursRemaining ч.';
    return 'менее часа';
  }

  Review copyWith({
    int? rating,
    String? comment,
    bool? canEdit,
    int? hoursRemaining,
  }) {
    return Review(
      id             : id,
      orderId        : orderId,
      masterId       : masterId,
      clientId       : clientId,
      rating         : rating ?? this.rating,
      comment        : comment ?? this.comment,
      createdAt      : createdAt,
      editableUntil  : editableUntil,
      updatedAt      : updatedAt,
      canEdit        : canEdit ?? this.canEdit,
      hoursRemaining : hoursRemaining ?? this.hoursRemaining,
    );
  }
}
