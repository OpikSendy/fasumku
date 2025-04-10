class ReportItem {
  final String title;
  final String category;
  final String facilityType;
  final String description;
  final String imagePath;
  final String status;
  final DateTime reportDate;
  final double latitude;
  final double longitude;
  final bool isWellMaintained;
  final bool isEasilyAccessible;

  ReportItem({
    required this.title,
    required this.category,
    required this.description,
    required this.imagePath,
    this.facilityType = 'Lainnya',
    this.status = 'Baru',
    DateTime? reportDate,
    this.latitude = -6.175392,
    this.longitude = 106.827153,
    this.isWellMaintained = false,
    this.isEasilyAccessible = false,
  }) : reportDate = reportDate ?? DateTime.now();
}