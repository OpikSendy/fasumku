import 'package:fasumku/view/detail/detail_screen.dart';
import 'package:fasumku/view/detail/facility_detail_screen.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FacilityReportScreen extends StatefulWidget {
  const FacilityReportScreen({super.key});

  @override
  State<FacilityReportScreen> createState() => _FacilityReportScreenState();
}

class _FacilityReportScreenState extends State<FacilityReportScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String? _selectedCategory;
  String? _selectedFacilityType;
  final TextEditingController _descriptionController = TextEditingController();

  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  final List<String> _categories = [
    'Taman',
    'Jalan',
    'Bangunan',
    'Transportasi',
    'Olahraga',
    'Lainnya'
  ];

  final Map<String, List<String>> _facilityTypes = {
    'Taman': ['Taman Kota', 'Taman Bermain', 'Taman Rekreasi', 'Hutan Kota'],
    'Jalan': ['Jalan Raya', 'Jembatan', 'Trotoar', 'Lampu Jalan', 'Rambu Lalu Lintas'],
    'Bangunan': ['Gedung Pemerintah', 'Gapura', 'Halte', 'Terminal', 'Toilet Umum'],
    'Transportasi': ['Stasiun', 'Terminal Bus', 'Parkir Umum', 'Halte Bus'],
    'Olahraga': ['Lapangan Sepak Bola', 'Lapangan Basket', 'Lapangan Voli', 'Kolam Renang'],
    'Lainnya': ['Lainnya']
  };

  List<String> get _currentFacilityTypes {
    return _selectedCategory != null ? _facilityTypes[_selectedCategory]! : [];
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.location,
    ].request();
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan lokasi')),
      );
    }
  }

  Future<void> _takePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sumber Gambar'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Ambil Foto'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _takePicture();
                  },
                ),
                const Divider(),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Pilih dari Galeri'),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFromGallery();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitReport() async {
    final supabase = Supabase.instance.client;
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon unggah foto fasilitas')),
        );
        return;
      }
      if (_selectedCategory == null || _selectedFacilityType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon pilih kategori dan jenis fasilitas')),
        );
        return;
      }
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mohon dapatkan lokasi terkini')),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Upload image to storage (optional, if using Supabase Storage)
        String? imageUrl;
        if (_imageFile != null) {
          final fileName = DateTime.now().millisecondsSinceEpoch.toString();
          final filePath = 'public/facilities/$fileName.jpg';
          await supabase.storage.from('facilities').upload(filePath, _imageFile!);
          imageUrl = supabase.storage.from('facilities').getPublicUrl(filePath);
        }

        // Insert facility report into the database
        await supabase.from('facilities').insert({
          'title': '${_selectedCategory} - ${_selectedFacilityType}',
          'category': _selectedCategory,
          'facility_type': _selectedFacilityType,
          'description': _descriptionController.text,
          'image_path': imageUrl ?? '',
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
          'is_well_maintained': false, // Replace with actual switch value
          'is_easily_accessible': false, // Replace with actual switch value
          'reported_by': supabase.auth.currentUser?.id, // Assuming user is authenticated
          'status': 'Baru',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan berhasil disimpan!')),
        );

        // Navigate to detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FacilityDetailPageCoba(
              imagePath: imageUrl,
              category: _selectedCategory!,
              facilityType: _selectedFacilityType!,
              description: _descriptionController.text,
              isWellMaintained: false, // Replace with actual switch value
              isEasilyAccessible: false, // Replace with actual switch value
              latitude: _currentPosition!.latitude,
              longitude: _currentPosition!.longitude,
              status: 'Baru',
              reportDate: DateTime.now(),
            ),
          ),
        );
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan laporan: $error')),
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
        title: const Text('Laporan Fasilitas Umum'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _imageFile != null ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _selectedCategory != null ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _descriptionController.text.isNotEmpty ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPosition != null ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Photo section
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
                      Text(
                        '1. Foto Fasilitas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ambil foto fasilitas umum secara jelas',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _imageFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                              : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ketuk untuk mengambil foto',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category section
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
                      Text(
                        '2. Kategori & Jenis',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pilih kategori dan jenis fasilitas',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          hintText: 'Pilih Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _selectedCategory,
                        items: _categories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                            _selectedFacilityType = null; // Reset facility type when changing category
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Jenis Fasilitas',
                          hintText: 'Pilih Jenis Fasilitas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _selectedFacilityType,
                        items: _selectedCategory == null
                            ? []
                            : _currentFacilityTypes.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: _selectedCategory == null
                            ? null
                            : (newValue) {
                          setState(() {
                            _selectedFacilityType = newValue;
                          });
                        },
                      ),
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
                      Text(
                        '3. Deskripsi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Berikan deskripsi detail tentang fasilitas',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi',
                          hintText: 'Masukkan deskripsi tentang kondisi fasilitas',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Mohon masukkan deskripsi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Condition assessment
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kondisi fasilitas terawat dengan baik?'),
                          Switch(
                            value: false,
                            onChanged: (value) {},
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fasilitas dapat diakses dengan mudah?'),
                          Switch(
                            value: false,
                            onChanged: (value) {},
                            activeColor: Colors.green,
                          ),
                        ],
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
                      Text(
                        '4. Lokasi',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Dapatkan lokasi fasilitas',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.grey.shade200,
                              ),
                              child: const Center(
                                child: Text('Peta Lokasi'),
                              ),
                            ),
                            Center(
                              child: Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null)
                        Center(
                          child: Text(
                            'Koordinat: ${_currentPosition!.latitude.toStringAsFixed(6)}, ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.my_location),
                          label: _isLoadingLocation
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text('Dapatkan Lokasi Terkini'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isLoadingLocation ? null : _getLocation,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _submitReport,
                  child: const Text(
                    'SIMPAN LAPORAN',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}