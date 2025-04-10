// models/facility_status_history.dart
class FacilityStatusHistory {
  final int? id;
  final int facilityId;
  final String oldStatus;
  final String newStatus;
  final String? note;
  final int? changedBy;
  final DateTime changedAt;
  final String? userName; // Not in database, but useful for display

  FacilityStatusHistory({
    this.id,
    required this.facilityId,
    required this.oldStatus,
    required this.newStatus,
    this.note,
    this.changedBy,
    DateTime? changedAt,
    this.userName,
  }) : changedAt = changedAt ?? DateTime.now();

  // Convert FacilityStatusHistory object to Map for database operations
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'facility_id': facilityId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'note': note,
      'changed_by': changedBy,
      'changed_at': changedAt.toIso8601String(),
    };
  }

  // Create FacilityStatusHistory object from Map (from database)
  factory FacilityStatusHistory.fromJson(Map<String, dynamic> json) {
    return FacilityStatusHistory(
      id: json['id'],
      facilityId: json['facility_id'],
      oldStatus: json['old_status'],
      newStatus: json['new_status'],
      note: json['note'],
      changedBy: json['changed_by'],
      changedAt: json['changed_at'] != null
          ? DateTime.parse(json['changed_at'])
          : DateTime.now(),
      userName: json['user_name'], // This might come from a JOIN query
    );
  }
}