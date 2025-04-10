import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fasumku/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      // User is already logged in, load user data
      await _databaseService.getCurrentUserId();
      // Use Future.microtask to schedule navigation after the current build cycle
      Future.microtask(() {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/report');
        }
      });
    }
    // If no session, stay on login screen
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Format the phone number correctly
        String phoneNumber = _phoneController.text;
        if (phoneNumber.startsWith('0')) {
          phoneNumber = phoneNumber.substring(1);
        }
        String formattedPhone = '+62$phoneNumber';

        // Fetch user data from the database
        final response = await supabase
            .from('users')
            .select('*') // Mengambil semua kolom
            .eq('phone', formattedPhone)
            .maybeSingle();

        if (response == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nomor telepon tidak terdaftar')),
          );
          return;
        }

        // Verify password hash
        if (response['password_hash'] != null &&
            BCrypt.checkpw(_passwordController.text, response['password_hash'])) {

          // Simpan data user menggunakan DatabaseService
          final dbService = DatabaseService();
          await dbService.saveUserData(response);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Login berhasil!')),
          );

          // Navigate to home screen or dashboard
          Navigator.pushReplacementNamed(context, '/report');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kata sandi salah')),
          );
        }
      } on PostgrestException catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error database: ${error.message}')),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $error')),
        );
      }
    }
  }

  // Future<void> _login() async {
  //   if (_formKey.currentState!.validate()) {
  //     try {
  //       // Format the phone number correctly
  //       String phoneNumber = _phoneController.text;
  //       if (phoneNumber.startsWith('0')) {
  //         phoneNumber = phoneNumber.substring(1);
  //       }
  //       String formattedPhone = '+62$phoneNumber';
  //
  //       // Fetch user data from the database
  //       final response = await supabase
  //           .from('users')
  //           .select()
  //           .eq('phone', formattedPhone)
  //           .maybeSingle();
  //
  //       if (response == null) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Nomor telepon tidak terdaftar')),
  //         );
  //         return;
  //       }
  //
  //       // Verify password hash
  //       if (response['password_hash'] != null &&
  //           BCrypt.checkpw(_passwordController.text, response['password_hash'])) {
  //
  //         // Gunakan phone auth atau metode custom auth
  //         final authResponse = await supabase.auth.signInWithPassword(
  //           phone: formattedPhone,
  //           password: _passwordController.text,
  //         );
  //
  //         // Check if session is created successfully
  //         if (authResponse.session != null) {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Login berhasil!')),
  //           );
  //
  //           // Navigate to home screen or dashboard
  //           Navigator.pushReplacementNamed(context, '/report');
  //         } else {
  //           ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('Gagal membuat sesi login')),
  //           );
  //         }
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(content: Text('Kata sandi salah')),
  //         );
  //       }
  //     } on AuthException catch (error) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error autentikasi: ${error.message}')),
  //       );
  //     } on PostgrestException catch (error) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error database: ${error.message}')),
  //       );
  //     } catch (error) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Terjadi kesalahan: $error')),
  //       );
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Blue background section (1/3 of screen height)
            Container(
              height: screenHeight / 3,
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Center(
                child: Image.asset(
                  'assets/img/fasumku.png',
                  width: 240,
                  height: 240,
                ),
              ),
            ),

            // White section with login form
            Container(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Phone number field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nomor telepon tidak boleh kosong';
                        }
                        if (!RegExp(r'^[0-9]{10,13}$').hasMatch(value)) {
                          return 'Nomor telepon tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Implement forgot password functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fitur belum tersedia')),
                          );
                        },
                        child: const Text(
                          'Lupa kata sandi?',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _login,
                        child: const Text(
                          'MASUK',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Create new account button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/registercoba');
                          // This is cleaner than using pushNamedAndRemoveUntil
                        },
                        child: const Text(
                          'BUAT AKUN BARU',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Credit
                    const Center(
                      child: Text(
                        '© 2025 FasumKu',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}