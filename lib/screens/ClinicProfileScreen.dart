import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:profil_Smile/core/services/storage_service.dart';

import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';

class ClinicTab extends StatefulWidget {
  const ClinicTab({super.key});

  @override
  State<ClinicTab> createState() => _ClinicTabState();
}

class _ClinicTabState extends State<ClinicTab> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;

  // ✅ Images
  String? _logoPath;
  String? _coverPath;
  File? _selectedLogoFile;
  File? _selectedCoverFile;

  // ═══════════════════════════════════════════════
  // Translation Helpers
  // ═══════════════════════════════════════════════
  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;

  // ═══════════════════════════════════════════════
  // Image URLs
  // ═══════════════════════════════════════════════
  String? get _logoUrl {
    if (_selectedLogoFile != null) return null;
    if (_logoPath == null || _logoPath!.isEmpty) return null;
    if (_logoPath!.startsWith('http')) return _logoPath;

    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    final cleanPath = _logoPath!.replaceAll(RegExp(r'^/+'), '');

    // ✅ إذا بدأ بـ storage، لا تكرره
    if (cleanPath.startsWith('storage/')) {
      return '$baseUrl/$cleanPath';
    }
    return '$baseUrl/storage/$cleanPath';
  }

  String? get _coverUrl {
    if (_selectedCoverFile != null) return null;
    if (_coverPath == null || _coverPath!.isEmpty) return null;
    if (_coverPath!.startsWith('http')) return _coverPath;

    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    final cleanPath = _coverPath!.replaceAll(RegExp(r'^/+'), '');

    if (cleanPath.startsWith('storage/')) {
      return '$baseUrl/$cleanPath';
    }
    return '$baseUrl/storage/$cleanPath';
  }

  // ═══════════════════════════════════════════════
  // Lifecycle
  // ═══════════════════════════════════════════════
  @override
  void initState() {
    super.initState();
    _fetchClinicData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════
  // Fetch Clinic Data
  // ═══════════════════════════════════════════════
  Future<void> _fetchClinicData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConstants.clinicProfile);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = (decoded is Map && decoded.containsKey('data'))
            ? decoded['data']
            : decoded;

        // ✅ استخرج clinic (قد تكون داخل data.clinic أو data مباشرة)
        final clinicData = data['clinic'] ?? data;

        if (mounted) {
          setState(() {
            _nameController.text =
                clinicData['name'] ?? clinicData['clinic_name'] ?? '';
            _phoneController.text =
                clinicData['phone'] ?? clinicData['mobile'] ?? '';
            _addressController.text = clinicData['address'] ?? '';

            // ✅ الصور
            _logoPath = clinicData['logo'];
            _coverPath = clinicData['cover'];

            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════
  // Pick Logo
  // ═══════════════════════════════════════════════
  Future<void> _pickLogo() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: Text(_t('gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (picked != null) {
                  setState(() => _selectedLogoFile = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: Text(_t('camera')),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 800,
                  maxHeight: 800,
                );
                if (picked != null) {
                  setState(() => _selectedLogoFile = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Pick Cover
  // ═══════════════════════════════════════════════
  Future<void> _pickCover() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: AppColors.primary,
              ),
              title: Text(_t('gallery')),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                  maxWidth: 1600,
                  maxHeight: 900,
                );
                if (picked != null) {
                  setState(() => _selectedCoverFile = File(picked.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: Text(_t('camera')),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                  maxWidth: 1600,
                  maxHeight: 900,
                );
                if (picked != null) {
                  setState(() => _selectedCoverFile = File(picked.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Update Clinic Profile (with images)
  // ═══════════════════════════════════════════════
  Future<void> _updateClinicProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final url = ApiConstants.updateClinicProfile;

      var request = http.MultipartRequest('POST', Uri.parse(url));

      // ═══ Headers ═══
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // ═══ Fields ═══
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['address'] = _addressController.text.trim();

      // ⚠️ مهم: لا نستخدم _method=PUT لأن الـ Route يدعم POST مباشرة

      // ═══ رفع الشعار ═══
      if (_selectedLogoFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('logo', _selectedLogoFile!.path),
        );
      }

      // ═══ رفع الغلاف ═══
      if (_selectedCoverFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('cover', _selectedCoverFile!.path),
        );
      }

      // ═══ Send ═══
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📤 Update URL: $url');
      debugPrint('📤 Status: ${response.statusCode}');
      debugPrint('📤 Body: ${response.body}');

      // ═══ Success ═══
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        final data = decoded['data'];
        final updatedClinic = data?['clinic'] ?? data;

        if (mounted) {
          setState(() {
            if (updatedClinic != null) {
              _nameController.text =
                  updatedClinic['name'] ?? _nameController.text;
              _phoneController.text =
                  updatedClinic['phone'] ?? _phoneController.text;
              _addressController.text =
                  updatedClinic['address'] ?? _addressController.text;

              // ✅ حدّث الصور
              _logoPath = updatedClinic['logo'];
              _coverPath = updatedClinic['cover'];

              _selectedLogoFile = null;
              _selectedCoverFile = null;

              // ✅ امسح كاش الصور
              imageCache.clear();
              imageCache.clearLiveImages();
            }
            _isSaving = false;
            _isEditing = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('clinic_updated_success')),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        // ═══ Error ═══
        if (mounted) {
          setState(() => _isSaving = false);
          String errorMsg = _t('save_failed');
          try {
            final err = jsonDecode(response.body);
            if (err['message'] != null) errorMsg = err['message'];
          } catch (_) {}
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Update error: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_t('connection_error')}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchClinicData,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══ Header (Cover + Logo) ═══
              _buildHeaderCard(),

              const SizedBox(height: 24),

              // ═══ Title + Edit Button ═══
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _t('clinic_management'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isEditing
                            ? Colors.red.withOpacity(0.1)
                            : AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _isEditing ? Icons.close_rounded : Icons.edit_rounded,
                        color: _isEditing ? Colors.red : AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ═══ Input Fields ═══
              _buildInputField(
                label: _t('clinic_name'),
                controller: _nameController,
                icon: Icons.store_rounded,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: _t('phone_number'),
                controller: _phoneController,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                enabled: _isEditing,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                label: _t('address'),
                controller: _addressController,
                icon: Icons.location_on_rounded,
                maxLines: 2,
                enabled: _isEditing,
              ),

              const SizedBox(height: 24),

              // ═══ Save Button ═══
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isSaving ? null : _updateClinicProfile,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_outlined, color: Colors.white),
                    label: Text(
                      _isSaving ? _t('saving') : _t('save_changes'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // Header Card (Cover + Logo)
  // ═══════════════════════════════════════════════
  Widget _buildHeaderCard() {
    return Column(
      children: [
        // ═══ Cover ═══
        GestureDetector(
          onTap: _isEditing ? _pickCover : null,
          child: Stack(
            children: [
              Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  image: _selectedCoverFile != null || _coverUrl != null
                      ? DecorationImage(
                          image: _selectedCoverFile != null
                              ? FileImage(_selectedCoverFile!)
                              : NetworkImage(_coverUrl!) as ImageProvider,
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: (_selectedCoverFile == null && _coverUrl == null)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.white.withOpacity(0.5),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isEditing
                                  ? _t('tap_to_pick_cover')
                                  : _t('no_cover'),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
              // ✅ Overlay عند التعديل
              if (_isEditing)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _t('change_cover'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ═══ Logo (Circular) ═══
        GestureDetector(
          onTap: _isEditing ? _pickLogo : null,
          child: Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: _selectedLogoFile != null || _logoUrl != null
                      ? DecorationImage(
                          image: _selectedLogoFile != null
                              ? FileImage(_selectedLogoFile!)
                              : NetworkImage(_logoUrl!) as ImageProvider,
                          fit: BoxFit.cover,
                          onError: (_, __) {},
                        )
                      : null,
                ),
                child: (_selectedLogoFile == null && _logoUrl == null)
                    ? const Icon(
                        Icons.local_hospital_rounded,
                        size: 45,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              // ✅ أيقونة الكاميرا عند التعديل
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ═══ Clinic Name ═══
        Text(
          _nameController.text.isNotEmpty
              ? _nameController.text
              : _t('clinic_management'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // ═══ Active Badge ═══
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.verified_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                _t('active_account'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // Input Field
  // ═══════════════════════════════════════════════
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled ? AppColors.primary : const Color(0xFFE2E8F0),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: enabled ? AppColors.textDark : const Color(0xFF64748B),
        ),
        validator: (value) {
          if (enabled && (value == null || value.trim().isEmpty)) {
            return _t('required_field');
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 13,
            color: enabled ? AppColors.primary : const Color(0xFF94A3B8),
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? AppColors.primary : const Color(0xFF94A3B8),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
