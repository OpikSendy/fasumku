import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

class RegisterScreenCoba extends StatefulWidget {
  const RegisterScreenCoba({super.key});

  @override
  RegisterScreenCobaState createState() => RegisterScreenCobaState();
}

class RegisterScreenCobaState extends State<RegisterScreenCoba> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPhoneVerified = false;
  bool _showOtpField = false;
  bool _isLoading = false;

  final supabase = Supabase.instance.client;

  String _dummyOtp = '';

  @override
  void initState() {
    super.initState();
    // Generate dummy OTP saat widget diinisialisasi
    _dummyOtp = _generateDummyOtp();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    // Remove leading zero if present
    if (phone.startsWith('0')) {
      phone = phone.substring(1);
    }
    // Add +62 prefix for Indonesian numbers
    return '+62$phone';
  }

  String _generateDummyOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<void> _sendDummyOtp() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor telepon terlebih dahulu')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Format phone number
      final formattedPhone = _formatPhoneNumber(_phoneController.text);

      // Check if phone number already registered
      final existingUser = await supabase
          .from('users')
          .select('phone')
          .eq('phone', formattedPhone)
          .maybeSingle();

      if (existingUser != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon sudah terdaftar')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Show dummy OTP in console for testing purposes
      debugPrint('Generated Dummy OTP: $_dummyOtp');

      setState(() {
        _showOtpField = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kode OTP dummy telah dibuat: $_dummyOtp')),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat OTP dummy: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyDummyOtp() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan kode OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_otpController.text == _dummyOtp) {
        setState(() {
          _isPhoneVerified = true;
          _showOtpField = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon berhasil diverifikasi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP tidak valid')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kesalahan verifikasi: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verifikasi nomor telepon terlebih dahulu')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Hash kata sandi
        final passwordHash = BCrypt.hashpw(
          _passwordController.text,
          BCrypt.gensalt(),
        );

        // Format phone number
        final formattedPhone = _formatPhoneNumber(_phoneController.text);

        // Simpan data pengguna ke tabel users
        await supabase.from('users').insert({
          'name': _nameController.text,
          'phone': formattedPhone,
          'password_hash': passwordHash,
          'is_phone_verified': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.')),
        );

        // Navigasi ke halaman login
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushNamed(context, '/login');
        });
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendaftar: $error')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun Baru'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lengkapi Data Diri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Nama lengkap
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Nomor telepon
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !_isPhoneVerified,
                      decoration: InputDecoration(
                        labelText: 'Nomor Telepon',
                        hintText: '81234567890 (tanpa awalan 0)',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        suffixIcon: _isPhoneVerified
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.phone_android),
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
                    const SizedBox(height: 16),
                    // Tombol Verifikasi Nomor
                    if (!_isPhoneVerified)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showOtpField ? null : _sendDummyOtp,
                          child: Text(
                            _showOtpField
                                ? 'OTP Terkirim'
                                : 'Verifikasi Nomor',
                            style: TextStyle(
                              color: _showOtpField ? Colors.grey : Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    // Field OTP
                    if (_showOtpField)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'Masukkan kode OTP dummy yang ditampilkan di konsol',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _otpController,
                                  keyboardType: TextInputType.number,
                                  maxLength: 6,
                                  decoration: InputDecoration(
                                    labelText: 'Kode OTP',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                    counterText: '',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Kode OTP tidak boleh kosong';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                                onPressed: _verifyDummyOtp,
                                child: const Text('Verifikasi'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    // Kata sandi
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Kata Sandi',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Kata sandi tidak boleh kosong';
                        }
                        if (value.length < 8) {
                          return 'Kata sandi minimal 8 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Konfirmasi kata sandi
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Kata Sandi',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi kata sandi tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Kata sandi tidak cocok';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    // Tombol Daftar
                    Center(
                      child: Text(
                        'Dengan mendaftar, Anda setuju dengan syarat dan ketentuan kami.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: _register,
                        child: const Text(
                          'DAFTAR',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Link ke halaman login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sudah memiliki akun? '),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}