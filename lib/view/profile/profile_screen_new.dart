import 'package:fasumku/widgets/buttons/custom_bottom_bar_profile.dart';
import 'package:fasumku/widgets/buttons/report_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fasumku/services//database_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final DatabaseService _databaseService = DatabaseService();

  // User data map that will be populated from Supabase
  Map<String, dynamic> _userData = {
    'name': '',
    'phoneNumber': '',
    'email': '',
    'address': '',
    'joinDate': DateTime.now(),
    'totalReports': 0,
  };

  final String _appVersion = '1.0.0';
  String _selectedLanguage = 'Bahasa Indonesia';
  final List<String> _availableLanguages = ['Bahasa Indonesia', 'English'];
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get current user ID
      final userId = await _databaseService.getCurrentUserId();

      // Fetch user data from Supabase
      final user = await _supabase
          .from('users')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (user == null) {
        throw Exception("User data not found");
      }

      // Fetch report count
      // final reportCount = await _supabase
      //     .from('reports')
      //     .select('count(*)')
      //     .eq('user_id', userId);

      // Convert the date string to DateTime
      final joinDate = user['created_at'] != null
          ? DateTime.parse(user['created_at'])
          : DateTime.now();

      setState(() {
        _userData = {
          'name': user['name'] ?? '',
          'phoneNumber': user['phone'] ?? '', // Memastikan nama field sesuai
          // 'email': user['email'] ?? '',
          // 'address': user['address'] ?? '',
          'joinDate': joinDate,
          'totalReports': 0,
          // 'totalReports': reportCount.isNotEmpty
          //     ? reportCount[0]['count']
          //     : 0, // Mengambil jumlah laporan
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error - could show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data profil: ${e.toString()}')),
      );

    }
  }

  // Perbaikan untuk metode logout
  Future<void> logout() async {
    await _databaseService.logout();
    // Arahkan pengguna ke halaman login setelah logout
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Get Supabase client instance
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Navigate to edit profile screen
              // After editing, should refresh data
              // Navigator.push(...).then((_) => _loadUserData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile header with user info
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // Account settings section
            _buildSection(
              title: 'Akun',
              children: [
                _buildSettingItem(
                  icon: Icons.person,
                  title: 'Informasi Pribadi',
                  onTap: () {
                    // Navigate to personal info screen
                  },
                ),
                _buildSettingItem(
                  icon: Icons.security,
                  title: 'Keamanan',
                  onTap: () {
                    // Navigate to security settings
                  },
                ),
                _buildSettingItem(
                  icon: Icons.history,
                  title: 'Riwayat Aktivitas',
                  onTap: () {
                    // Navigate to activity history
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // App settings section
            _buildSection(
              title: 'Pengaturan Aplikasi',
              children: [
                _buildSwitchItem(
                  icon: Icons.notifications,
                  title: 'Notifikasi',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    // Save notification preference to database
                    _updateUserPreference('notifications_enabled', value);
                  },
                ),
                _buildSwitchItem(
                  icon: Icons.location_on,
                  title: 'Lokasi',
                  value: _locationEnabled,
                  onChanged: (value) {
                    setState(() {
                      _locationEnabled = value;
                    });
                    // Save location preference to database
                    _updateUserPreference('location_enabled', value);
                  },
                ),
                _buildLanguageSelector(),
              ],
            ),

            const SizedBox(height: 16),

            // About section
            _buildSection(
              title: 'Tentang',
              children: [
                _buildSettingItem(
                  icon: Icons.info,
                  title: 'Tentang FasumKu',
                  onTap: () {
                    // Show about dialog
                  },
                ),
                _buildSettingItem(
                  icon: Icons.help,
                  title: 'Bantuan',
                  onTap: () {
                    // Navigate to help screen
                  },
                ),
                _buildSettingItem(
                  icon: Icons.assignment,
                  title: 'Ketentuan Penggunaan',
                  onTap: () {
                    // Show terms of use
                  },
                ),
                _buildVersionInfo(),
              ],
            ),

            const SizedBox(height: 16),

            // Logout button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    _showLogoutConfirmation();
                  },
                  child: const Text(
                    'KELUAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ReportButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomAppBarProfile(),
    );
  }

  // Update user preference in Supabase
  Future<void> _updateUserPreference(String preferenceName, dynamic value) async {
    try {
      final userId = await _databaseService.getCurrentUserId();
      await _supabase
          .from('user_preferences')
          .upsert({
        'user_id': userId,
        preferenceName: value,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan pengaturan: ${e.toString()}')),
      );
    }
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person,
              size: 60,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userData['name'],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userData['phoneNumber'],
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Laporan', _userData['totalReports'].toString()),
              const SizedBox(width: 24),
              _buildStatItem(
                'Bergabung',
                '${_userData['joinDate'].day}/${_userData['joinDate'].month}/${_userData['joinDate'].year}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.language, color: Colors.blue),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Bahasa',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          DropdownButton<String>(
            value: _selectedLanguage,
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedLanguage = newValue;
                });
                // Save language preference to database
                _updateUserPreference('language', newValue);
              }
            },
            items: _availableLanguages.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            underline: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.android, color: Colors.blue),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Versi Aplikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _appVersion,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Anda yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('BATAL'),
          ),
          TextButton(
            onPressed: () {
              logout();
            },
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
  }
}