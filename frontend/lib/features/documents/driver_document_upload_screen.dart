import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../core/services/storage_service.dart';
import '../../navigation/main_navigation.dart';
import '../../core/extensions/translation_extension.dart';

class DriverDocumentUploadScreen extends StatefulWidget {
  const DriverDocumentUploadScreen({super.key});

  @override
  State<DriverDocumentUploadScreen> createState() => _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState extends State<DriverDocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();
  
  File? _nationalIdPhoto;
  File? _driverLicensePhoto;
  File? _carRegistration;
  File? _carPhotoFront;
  File? _carPhotoSide;
  
  bool _isUploading = false;
  String _verificationStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _checkDocumentStatus();
  }

  Future<void> _checkDocumentStatus() async {
    try {
      final token = await StorageService.getToken();
      
      final response = await http.get(
        Uri.parse("${StorageService.baseUrl}/accounts/driver/documents/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _verificationStatus = data['verification_status'] ?? 'pending';
        });
        
        // If already approved, go to main app
        if (data['is_verified'] == true) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainNavigation()),
          );
        }
      }
    } catch (e) {
      print("Error checking status: $e");
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          switch (type) {
            case 'national_id':
              _nationalIdPhoto = File(image.path);
              break;
            case 'driver_license':
              _driverLicensePhoto = File(image.path);
              break;
            case 'car_registration':
              _carRegistration = File(image.path);
              break;
            case 'car_front':
              _carPhotoFront = File(image.path);
              break;
            case 'car_side':
              _carPhotoSide = File(image.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking image: $e")),
      );
    }
  }

  Future<void> _uploadDocuments() async {
    // Validate all documents are selected
    if (_nationalIdPhoto == null ||
        _driverLicensePhoto == null ||
        _carRegistration == null ||
        _carPhotoFront == null ||
        _carPhotoSide == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload all required documents")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final token = await StorageService.getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("${StorageService.baseUrl}/accounts/driver/upload-documents/"),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Add files
      request.files.add(await http.MultipartFile.fromPath(
        'national_id_photo',
        _nationalIdPhoto!.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'driver_license_photo',
        _driverLicensePhoto!.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'car_registration',
        _carRegistration!.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'car_photo_front',
        _carPhotoFront!.path,
      ));
      
      request.files.add(await http.MultipartFile.fromPath(
        'car_photo_side',
        _carPhotoSide!.path,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Success! 🎉"),
              content: const Text(
                "Documents uploaded successfully! Your application is now under review. You'll receive a notification once approved.",
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const MainNavigation()),
                    );
                  },
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception("Upload failed: ${response.body}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Upload Driver Documents"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify Your Driver Account",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Upload the following documents to get verified as a driver",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            _buildDocumentCard(
              title: "National ID",
              icon: Icons.badge,
              file: _nationalIdPhoto,
              onTap: () => _pickImage('national_id'),
            ),
            
            _buildDocumentCard(
              title: "Driver's License",
              icon: Icons.credit_card,
              file: _driverLicensePhoto,
              onTap: () => _pickImage('driver_license'),
            ),
            
            _buildDocumentCard(
              title: "Car Registration",
              icon: Icons.description,
              file: _carRegistration,
              onTap: () => _pickImage('car_registration'),
            ),
            
            _buildDocumentCard(
              title: "Car Photo (Front)",
              icon: Icons.directions_car,
              file: _carPhotoFront,
              onTap: () => _pickImage('car_front'),
            ),
            
            _buildDocumentCard(
              title: "Car Photo (Side)",
              icon: Icons.directions_car_outlined,
              file: _carPhotoSide,
              onTap: () => _pickImage('car_side'),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Upload Documents",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            
            
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1E3A8A)),
        title: Text(title),
        subtitle: Text(
          file == null ? "Tap to upload" : "✓ Selected",
          style: TextStyle(
            color: file == null ? Colors.grey : Colors.green,
          ),
        ),
        trailing: file == null
            ? const Icon(Icons.upload_file)
            : const Icon(Icons.check_circle, color: Colors.green),
        onTap: onTap,
      ),
    );
  }
}