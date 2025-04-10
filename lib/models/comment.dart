// lib/models/comment.dart
class Comment {
  final int? id;
  final int facilityId;
  final String text;
  final int? userId;
  final Map<String, dynamic>? user;
  final DateTime? createdAt;

  Comment({
    this.id,
    required this.facilityId,
    required this.text,
    this.userId,
    this.user,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      facilityId: json['facility_id'],
      text: json['text'] ?? '',
      userId: json['user_id'],
      user: json['user'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facility_id': facilityId,
      'text': text,
      'user_id': userId,
    };
  }
}