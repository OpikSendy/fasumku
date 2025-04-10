import 'package:flutter/material.dart';

class EditStatusPage extends StatefulWidget {
  final String currentStatus;
  final DateTime reportDate;

  const EditStatusPage({
    super.key,
    required this.currentStatus,
    required this.reportDate,
  });

  @override
  State<EditStatusPage> createState() => _EditStatusPageState();
}

class _EditStatusPageState extends State<EditStatusPage> {
  late String selectedStatus;
  final List<String> statusOptions = ['Baru', 'Menunggu', 'Diproses', 'Selesai'];
  String? statusNote;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.currentStatus;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Status Fasilitas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status info card
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
                        const Icon(Icons.info_outline, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Informasi Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Status Saat Ini:',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(widget.currentStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tanggal Laporan: ${_formatDate(widget.reportDate)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Select new status
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
                          'Perbarui Status',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih status baru:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Status options
                    ...statusOptions.map((status) => _buildStatusOption(status)),

                    const SizedBox(height: 16),
                    const Text(
                      'Catatan Status (Opsional):',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Masukkan catatan terkait perubahan status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          statusNote = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('SIMPAN PERUBAHAN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Return the selected status and note to the previous page
                Navigator.pop(
                    context,
                    {
                      'status': selectedStatus,
                      'note': _noteController.text.isNotEmpty ? _noteController.text : null
                    }
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusOption(String status) {
    final bool isSelected = selectedStatus == status;
    final Color statusColor = _getStatusColor(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedStatus = status;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? statusColor : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            color: isSelected ? statusColor.withOpacity(0.1) : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? statusColor : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? statusColor : Colors.black,
                ),
              ),
              const Spacer(),
              if (isSelected) _buildStatusBadge(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color statusColor = _getStatusColor(status);
    final IconData statusIcon = _getStatusIcon(status);

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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return Colors.blue;
      case 'menunggu':
        return Colors.orange;
      case 'diproses':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'baru':
        return Icons.fiber_new;
      case 'menunggu':
        return Icons.hourglass_empty;
      case 'diproses':
        return Icons.engineering;
      case 'selesai':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}