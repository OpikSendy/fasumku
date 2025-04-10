import 'package:fasumku/view/edit/edit_status_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:fasumku/models/facility.dart'; // Model untuk facility
import 'package:fasumku/models/comment.dart'; // Model untuk comment
import 'package:fasumku/models/facility_status_history.dart'; // Model untuk history
import 'package:fasumku/services/database_service.dart'; // Service untuk database

class FacilityDetailPage extends StatefulWidget {
  final int? facilityId; // ID fasilitas dari database
  final File? imageFile; // File gambar baru (jika ada)
  final Facility? facility; // Data fasilitas lengkap (jika sudah ada)

  const FacilityDetailPage({
    super.key,
    this.facilityId,
    this.imageFile,
    this.facility,
  });

  @override
  State<FacilityDetailPage> createState() => _FacilityDetailPageState();
}

class _FacilityDetailPageState extends State<FacilityDetailPage> {
  bool isLoading = true;
  late Facility _facility;
  List<Comment> _comments = [];
  List<FacilityStatusHistory> _statusHistory = [];
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    try {
      if (widget.facility != null) {
        // Jika facility sudah dilewatkan sebagai parameter
        _facility = widget.facility!;
      } else if (widget.facilityId != null) {
        // Jika hanya ID yang dilewatkan, ambil data dari database
        _facility = await _dbService.getFacilityById(widget.facilityId!);
      } else {
        // Jika ini fasilitas baru yang belum disimpan
        throw Exception("Tidak ada data fasilitas yang valid");
      }

      // Ambil data komentar untuk fasilitas ini
      if (_facility.id != null) {
        _comments = await _dbService.getCommentsByFacilityId(_facility.id!);
        _statusHistory = await _dbService.getStatusHistoryByFacilityId(_facility.id!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(String newStatus, String? note) async {
    try {
      if (_facility.id == null) {
        throw Exception("ID fasilitas tidak valid");
      }

      // Simpan status lama untuk history
      final oldStatus = _facility.status;

      // Update status fasilitas
      await _dbService.updateFacilityStatus(
        _facility.id!,
        newStatus,
        note,
      );

      // Tambahkan ke history
      await _dbService.addStatusHistory(
          FacilityStatusHistory(
            facilityId: _facility.id!,
            oldStatus: oldStatus,
            newStatus: newStatus,
            note: note,
            changedBy: await _dbService.getCurrentUserId(),
          )
      );

      // Perbarui data lokal
      setState(() {
        _facility = _facility.copyWith(
          status: newStatus,
          statusNote: note,
        );
      });

      // Muat ulang history
      _statusHistory = await _dbService.getStatusHistoryByFacilityId(_facility.id!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memperbarui status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addComment(String commentText) async {
    try {
      if (_facility.id == null) {
        throw Exception("ID fasilitas tidak valid");
      }

      final userId = await _dbService.getCurrentUserId();
      final comment = Comment(
        facilityId: _facility.id!,
        text: commentText,
        userId: userId,
      );

      // Simpan komentar ke database
      await _dbService.addComment(comment);

      // Muat ulang komentar
      _comments = await _dbService.getCommentsByFacilityId(_facility.id!);
      setState(() {});

      // Clear comment field
      _commentController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Komentar berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menambahkan komentar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail Fasilitas Umum'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Fasilitas Umum'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Membagikan detail fasilitas')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with category tag overlay
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: widget.imageFile != null
                            ? Image.file(
                          widget.imageFile!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : _facility.imagePath != null
                            ? Image.network(
                          _facility.imagePath!,
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 250,
                              width: double.infinity,
                              color: Colors.grey.shade300,
                              child: const Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                            : Container(
                          height: 250,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _facility.category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Facility info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _facility.title, // Judul dari database
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _facility.facilityType ?? 'Tidak ada tipe',
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Koordinat: ${_facility.latitude.toStringAsFixed(6)}, ${_facility.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Status section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.update, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        _buildStatusBadge(_facility.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tanggal Laporan:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_facility.reportDate.day}/${_facility.reportDate.month}/${_facility.reportDate.year}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text('UBAH STATUS'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditStatusPage(
                                  currentStatus: _facility.status,
                                  reportDate: _facility.reportDate,
                                ),
                              ),
                            );

                            if (result != null && result is Map<String, dynamic>) {
                              await _updateStatus(result['status'], result['note']);
                            }
                          },
                        ),
                      ],
                    ),

                    if (_facility.statusNote != null && _facility.statusNote!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Catatan:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _facility.statusNote!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Status history section
                    if (_statusHistory.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Riwayat Status:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: _statusHistory.map((history) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 16,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${history.oldStatus} → ${history.newStatus} ',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: '(${_formatDate(history.changedAt)})',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (history.note != null && history.note!.isNotEmpty)
                                          TextSpan(
                                            text: '\n${history.note}',
                                            style: TextStyle(
                                              fontStyle: FontStyle.italic,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Deskripsi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _facility.description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Condition section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assessment, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Kondisi Fasilitas',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildConditionItem(
                      'Terawat dengan baik',
                      _facility.isWellMaintained,
                    ),
                    const Divider(height: 24),
                    _buildConditionItem(
                      'Dapat diakses dengan mudah',
                      _facility.isEasilyAccessible,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Lokasi',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  // A placeholder for now, you can replace with an actual map implementation
                                  Container(
                                    width: double.infinity,
                                    color: Colors.grey.shade200,
                                    child: Center(
                                      child: Text(
                                        'Latitude: ${_facility.latitude}\nLongitude: ${_facility.longitude}',
                                        style: TextStyle(color: Colors.grey.shade700),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Icon(
                                      Icons.location_on,
                                      color: Colors.red,
                                      size: 30,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Center(
                            child: Icon(
                              Icons.location_on,
                              color: Colors.red,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Koordinat: ${_facility.latitude.toStringAsFixed(6)}, ${_facility.longitude.toStringAsFixed(6)}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comments section (Updated for new Comment model)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.comment, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Komentar',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Comment input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: 'Tambahkan komentar...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _addComment(value);
                              }
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: Colors.blue,
                          onPressed: () {
                            final commentText = _commentController.text.trim();
                            if (commentText.isNotEmpty) {
                              _addComment(commentText);
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Comments list
                    if (_comments.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Belum ada komentar',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _comments.map((comment) {
                          // Get user name from comment.user data if available
                          String? userName;
                          if (comment.user != null && comment.user!.containsKey('name')) {
                            userName = comment.user!['name'] as String?;
                          }

                          // Get first initial for avatar
                          String initial = 'U';
                          if (userName != null && userName.isNotEmpty) {
                            initial = userName[0].toUpperCase();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            userName ?? 'Pengguna',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            comment.createdAt != null
                                                ? _formatDate(comment.createdAt!)
                                                : 'Baru saja',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        comment.text,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('EDIT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // Navigate back to edit screen
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.report_problem),
                    label: const Text('LAPORKAN'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Fitur laporan masalah')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'baru':
        statusColor = Colors.blue;
        statusIcon = Icons.fiber_new;
        break;
      case 'menunggu':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'diproses':
        statusColor = Colors.purple;
        statusIcon = Icons.engineering;
        break;
      case 'selesai':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionItem(String title, bool condition) {
    return Row(
      children: [
        Icon(
          condition ? Icons.check_circle : Icons.cancel,
          color: condition ? Colors.green : Colors.red,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: condition ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: condition ? Colors.green : Colors.red,
              width: 1,
            ),
          ),
          child: Text(
            condition ? 'Ya' : 'Tidak',
            style: TextStyle(
              color: condition ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}