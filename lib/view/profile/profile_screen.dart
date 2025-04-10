import 'package:fasumku/widgets/buttons/custom_bottom_bar_profile.dart';
import 'package:fasumku/widgets/buttons/report_button.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  // Sample user data - in a real app, this would come from a user model
  final Map<String, dynamic> _userData = {
    'name': 'Ahmad Fadillah',
    'phoneNumber': '081234567890',
    'email': 'ahmad.fadillah@example.com',
    'address': 'Jl. Merdeka No. 123, Jakarta',
    'joinDate': DateTime(2023, 5, 15),
    'totalReports': 8,
  };

  final String _appVersion = '1.0.0';
  String _selectedLanguage = 'Bahasa Indonesia';
  final List<String> _availableLanguages = ['Bahasa Indonesia', 'English'];
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

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
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
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
              Navigator.pop(context);
              Navigator.pushNamed(context, '/');
            },
            child: const Text('KELUAR'),
          ),
        ],
      ),
    );
  }
}