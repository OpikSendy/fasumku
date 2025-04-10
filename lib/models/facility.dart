// models/facility.dart
class Facility {
  final int? id;
  final String title;
  final String category;
  final String? facilityType;
  final String description;
  final String? imagePath;
  final double latitude;
  final double longitude;
  final bool isWellMaintained;
  final bool isEasilyAccessible;
  final int? reportedBy;
  final String status;
  final String? statusNote;
  final DateTime reportDate;

  Facility({
    this.id,
    required this.title,
    required this.category,
    this.facilityType,
    required this.description,
    this.imagePath,
    required this.latitude,
    required this.longitude,
    required this.isWellMaintained,
    required this.isEasilyAccessible,
    this.reportedBy,
    this.status = 'Baru',
    this.statusNote,
    DateTime? reportDate,
  }) : reportDate = reportDate ?? DateTime.now();

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      facilityType: json['facility_type'],
      description: json['description'] ?? '',
      imagePath: json['image_path'],
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      isWellMaintained: json['is_well_maintained'] ?? false,
      isEasilyAccessible: json['is_easily_accessible'] ?? false,
      reportedBy: json['reported_by'],
      status: json['status'] ?? 'Baru',
      statusNote: json['status_note'],
      reportDate: DateTime.parse(json['report_date']),
    );
  }

  // Convert Facility object to Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'facility_type': facilityType,
      'description': description,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'is_well_maintained': isWellMaintained,
      'is_easily_accessible': isEasilyAccessible,
      'reported_by': reportedBy,
      'status': status,
      'status_note': statusNote,
      'report_date': reportDate.toIso8601String(),
    };
  }

  // Create Facility object from Map (from database)
  factory Facility.fromMap(Map<String, dynamic> map) {
    return Facility(
      id: map['id'],
      title: map['title'],
      category: map['category'],
      facilityType: map['facility_type'],
      description: map['description'],
      imagePath: map['image_path'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      isWellMaintained: map['is_well_maintained'] ?? false,
      isEasilyAccessible: map['is_easily_accessible'] ?? false,
      reportedBy: map['reported_by'],
      status: map['status'] ?? 'Baru',
      statusNote: map['status_note'],
      reportDate: map['report_date'] != null
          ? DateTime.parse(map['report_date'])
          : DateTime.now(),
    );
  }

  // Create a copy of this Facility with modified fields
  Facility copyWith({
    int? id,
    String? title,
    String? category,
    String? facilityType,
    String? description,
    String? imagePath,
    double? latitude,
    double? longitude,
    bool? isWellMaintained,
    bool? isEasilyAccessible,
    int? reportedBy,
    String? status,
    String? statusNote,
    DateTime? reportDate,
  }) {
    return Facility(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      facilityType: facilityType ?? this.facilityType,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isWellMaintained: isWellMaintained ?? this.isWellMaintained,
      isEasilyAccessible: isEasilyAccessible ?? this.isEasilyAccessible,
      reportedBy: reportedBy ?? this.reportedBy,
      status: status ?? this.status,
      statusNote: statusNote ?? this.statusNote,
      reportDate: reportDate ?? this.reportDate,
    );
  }
}