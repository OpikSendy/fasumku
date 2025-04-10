import 'package:fasumku/widgets/buttons/custom_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:fasumku/view/detail/facility_detail_screen.dart';
import 'package:fasumku/widgets/buttons/report_button.dart';
import 'package:fasumku/models/facility.dart';
import 'package:fasumku/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  ReportsScreenState createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filterOptions = ['Semua Laporan', 'Laporan Saya', 'Laporan Selesai', 'Laporan Menunggu', 'Laporan Diproses'];
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isLoading = true;
  List<Facility> _facilities = [];
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Perbaikan untuk metode _checkLoginStatus
  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await _databaseService.isLoggedIn();
    if (!isLoggedIn) {
      _showLoginScreen();
    } else {
      _loadFacilities();
    }
  }

  // Perbaikan untuk metode _showLoginScreen
  Future<void> _showLoginScreen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false); // Reset login status
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _loadFacilities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final facilities = await _databaseService.getAllFacilities();
      setState(() {
        _facilities = facilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading facilities: $e');
      // Show error message to user
    }
  }

  List<Facility> get filteredFacilities {
    List<Facility> results = List.from(_facilities);

    // Apply search filter if searching
    if (_isSearching && _searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      results = results.where((facility) {
        return facility.title.toLowerCase().contains(query) ||
            facility.description.toLowerCase().contains(query) ||
            facility.category.toLowerCase().contains(query) ||
            facility.facilityType.toString().contains(query);
      }).toList();
    }

    // Apply category filter
    switch (_selectedFilterIndex) {
      case 1: // Laporan Saya
      // Get current user ID from your auth service
      // String currentUserId = _authService.currentUser?.id ?? '';
      // results = results.where((facility) => facility.createdBy == currentUserId).toList();
      // For now, showing half of the reports as a placeholder
        results = results.take(results.length ~/ 2).toList();
        break;
      case 2: // Laporan Selesai
        results = results.where((facility) => facility.status == 'Selesai').toList();
        break;
      case 3: // Laporan Menunggu
        results = results.where((facility) => facility.status == 'Menunggu').toList();
        break;
      case 4: // Laporan Diproses
        results = results.where((facility) => facility.status == 'Diproses').toList();
        break;
      default: // Semua Laporan
        break;
    }

    // Sort by date (newest first)
    results.sort((a, b) => b.reportDate.compareTo(a.reportDate));

    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Cari laporan...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (_) => setState(() {}),
        )
            : const Text('Laporan Fasilitas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFacilities,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Statistics cards
          _buildStatisticsCards(),

          // Reports list
          Expanded(
            child: filteredFacilities.isEmpty
                ? _buildEmptyState()
                : _buildReportsList(),
          ),
        ],
      ),
      floatingActionButton: ReportButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomAppBar(),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterOptions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterOptions[index]),
              selected: _selectedFilterIndex == index,
              onSelected: (selected) {
                setState(() {
                  _selectedFilterIndex = index;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.blue.withOpacity(0.2),
              checkmarkColor: Colors.blue,
              labelStyle: TextStyle(
                color: _selectedFilterIndex == index ? Colors.blue : Colors.black87,
                fontWeight: _selectedFilterIndex == index ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _selectedFilterIndex == index ? Colors.blue : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildStatCard('Total Laporan', _facilities.length.toString(), Colors.blue),
          _buildStatCard('Menunggu', _facilities.where((f) => f.status == 'Menunggu').length.toString(), Colors.orange),
          _buildStatCard('Diproses', _facilities.where((f) => f.status == 'Diproses').length.toString(), Colors.purple),
          _buildStatCard('Selesai', _facilities.where((f) => f.status == 'Selesai').length.toString(), Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: filteredFacilities.length,
        itemBuilder: (context, index) {
          final facility = filteredFacilities[index];
          return _buildReportCard(facility);
        },
      ),
    );
  }

  Widget _buildReportCard(Facility facility) {
    // Map status to colors
    final Map<String, Color> statusColors = {
      'Baru': Colors.blue,
      'Menunggu': Colors.orange,
      'Diproses': Colors.purple,
      'Selesai': Colors.green,
    };

    final Color statusColor = statusColors[facility.status] ?? Colors.grey;

    return GestureDetector(
      onTap: () => _navigateToDetailPage(facility),
      child: Card(
        elevation: 2,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and status badge
            Stack(
              children: [
                facility.imagePath != null && facility.imagePath!.isNotEmpty
                    ? Image.network(
                  facility.imagePath!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 120,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  ),
                )
                    : Container(
                  height: 120,
                  width: double.infinity,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      facility.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Text(
                      facility.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(6.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    facility.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          facility.facilityType.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    facility.description,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(facility.reportDate),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada laporan ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau kata kunci pencarian',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Laporan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Status',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(_filterOptions.length, (index) {
                      return ChoiceChip(
                        label: Text(_filterOptions[index]),
                        selected: _selectedFilterIndex == index,
                        onSelected: (selected) {
                          setState(() {
                            this.setState(() {
                              _selectedFilterIndex = index;
                            });
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Kategori',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      'Semua', 'Taman', 'Jalan', 'Bangunan', 'Transportasi', 'Olahraga', 'Lainnya'
                    ].map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: false,
                        onSelected: (selected) {
                          // Implementation for category filter would go here
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terapkan Filter'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _navigateToDetailPage(Facility facility) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FacilityDetailPage(
          facilityId: facility.id,
          facility: facility,
        ),
      ),
    ).then((_) {
      // Refresh the list when returning from detail page
      _loadFacilities();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit lalu';
      }
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}