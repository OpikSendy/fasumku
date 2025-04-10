import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OtpService {
  final supabase = Supabase.instance.client;

  // Generating a random OTP code
  String generateOtp() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  // Store OTP in database with expiration
  Future<void> saveOtp(String phone, String otp) async {
    final expiryTime = DateTime.now().add(const Duration(minutes: 5));

    try {
      // Check if an OTP record already exists for this phone
      final existingOtp = await supabase
          .from('otps')
          .select()
          .eq('phone', phone)
          .maybeSingle();

      if (existingOtp != null) {
        // Update existing OTP
        await supabase
            .from('otps')
            .update({
          'code': otp,
          'expires_at': expiryTime.toIso8601String(),
          'verified': false
        })
            .eq('phone', phone);
      } else {
        // Create new OTP record
        await supabase
            .from('otps')
            .insert({
          'phone': phone,
          'code': otp,
          'expires_at': expiryTime.toIso8601String(),
          'verified': false
        });
      }
    } catch (e) {
      throw Exception('Failed to save OTP: $e');
    }
  }

  // Verify OTP code
  Future<bool> verifyOtp(String phone, String otp) async {
    try {
      final response = await supabase
          .from('otps')
          .select()
          .eq('phone', phone)
          .eq('code', otp)
          .gt('expires_at', DateTime.now().toIso8601String())
          .single();

      // Mark OTP as verified
      await supabase
          .from('otps')
          .update({'verified': true})
          .eq('id', response['id']);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Send OTP via local SMS provider
  Future<bool> sendSmsOtp(String phone, String otp) async {
    const twilioAccountSid = 'VA98814cf1ba67a335ac1c6975595ab501';
    const twilioAuthToken = '766185196606b24217006f1716afbd09';
    const twilioPhoneNumber = '+6281381534309'; // Nomor telepon Twilio
    const apiUrl = 'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Messages.json';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$twilioAccountSid:$twilioAuthToken'))}',
        },
        body: {
          'From': twilioPhoneNumber,
          'To': phone,
          'Body': 'Kode OTP Anda adalah: $otp. Kode ini berlaku selama 5 menit.',
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to send SMS: ${response.body}');
      }
    } catch (e) {
      throw Exception('SMS sending error: $e');
    }
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  RegisterScreenState createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
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
  final OtpService _otpService = OtpService();

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

  // Kirim OTP ke nomor telepon
  Future<void> _sendOtp() async {
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

      // Generate OTP
      final otp = _otpService.generateOtp();

      // Save OTP to database
      await _otpService.saveOtp(formattedPhone, otp);

      // Send OTP via SMS
      await _otpService.sendSmsOtp(formattedPhone, otp);

      setState(() {
        _showOtpField = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode OTP telah dikirim ke nomor telepon Anda')),
      );

      // For development/testing only - show OTP in console
      debugPrint('Generated OTP: $otp');

    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim OTP: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Verifikasi OTP
  Future<void> _verifyOtp() async {
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
      final formattedPhone = _formatPhoneNumber(_phoneController.text);
      final isVerified = await _otpService.verifyOtp(
        formattedPhone,
        _otpController.text,
      );

      if (isVerified) {
        setState(() {
          _isPhoneVerified = true;
          _showOtpField = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nomor telepon berhasil diverifikasi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode OTP tidak valid atau sudah kedaluwarsa')),
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

  // Registrasi Pengguna
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
          const SnackBar(content: Text('Pendaftaran berhasil! Silahkan masuk.')),
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
                          onPressed: _showOtpField ? null : _sendOtp,
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
                            'Masukkan kode OTP yang dikirim ke nomor telepon Anda',
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
                                onPressed: _verifyOtp,
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
                            Navigator.pushNamed(context, '/login');
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