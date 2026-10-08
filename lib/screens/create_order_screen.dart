import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _patientController = TextEditingController();
  final TextEditingController _patientNumberController =
      TextEditingController();
  final TextEditingController _xmlNumberController = TextEditingController();
  final TextEditingController _orderDateController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _sessionTimeController = TextEditingController();
  final TextEditingController _shadeController = TextEditingController();
  final TextEditingController _additionalNotesController =
      TextEditingController();

  dynamic _selectedDoctorId;
  dynamic _selectedProstheticTypeId;
  dynamic _selectedStartStageId;

  List<dynamic> _doctorsList = [];
  List<dynamic> _prostheticTypesList = [];
  List<dynamic> _stagesList = [];
  bool _isLoadingData = true;

  File? _selectedImage;
  String? _uploadedImagePath;
  bool _isUploadingImage = false;
  final ImagePicker _picker = ImagePicker();

  bool _isSubmitting = false;

  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;
  String _tArgs(String key, Map<String, String> args) =>
      _loc?.translateWithArgs(key, args) ?? key;
  bool get _isRTL => Localizations.localeOf(context).languageCode == 'ar';

  @override
  void initState() {
    super.initState();
    _orderDateController.text = DateTime.now().toString().split(' ')[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialData();
    });
  }

  @override
  void dispose() {
    _patientController.dispose();
    _patientNumberController.dispose();
    _xmlNumberController.dispose();
    _orderDateController.dispose();
    _deliveryDateController.dispose();
    _sessionTimeController.dispose();
    _shadeController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() => _isLoadingData = true);

    try {
      final doctorsRes = await ApiService.get(ApiConstants.clinicDoctors);
      final prostheticRes = await ApiService.get(ApiConstants.prostheticTypes);

      if (mounted) {
        setState(() {
          if (doctorsRes.statusCode == 200 || doctorsRes.statusCode == 201) {
            final docData = jsonDecode(doctorsRes.body);
            _doctorsList = docData is List ? docData : (docData['data'] ?? []);
          }

          if (prostheticRes.statusCode == 200 ||
              prostheticRes.statusCode == 201) {
            final prosthData = jsonDecode(prostheticRes.body);
            _prostheticTypesList = prosthData is List
                ? prosthData
                : (prosthData['data'] ?? []);
          }

          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _showImagePickerModal() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    _t('gallery'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    _t('camera'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );
    if (pickedFile == null) return;

    setState(() {
      _selectedImage = File(pickedFile.path);
      _isUploadingImage = true;
      _uploadedImagePath = null;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://magichandsapp.com/lab/upload.php'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', pickedFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() {
            _uploadedImagePath = data['file_path'];
          });
        } else {
          _showSnackBar(
            data['message'] ?? _t('file_upload_failed'),
            Colors.red,
          );
          setState(() => _selectedImage = null);
        }
      } else {
        _showSnackBar(_t('image_upload_server_error'), Colors.red);
        setState(() => _selectedImage = null);
      }
    } catch (e) {
      _showSnackBar('${_t("image_upload_connection_error")}: $e', Colors.red);
      setState(() => _selectedImage = null);
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  void _calculateExpectedDeliveryDate() {
    int daysToAdd = 0;

    if (_selectedStartStageId != null && _stagesList.isNotEmpty) {
      final selectedStage = _stagesList.firstWhere(
        (e) => e['id'] == _selectedStartStageId,
        orElse: () => null,
      );
      if (selectedStage != null) {
        daysToAdd =
            selectedStage['expected_days'] ?? selectedStage['days'] ?? 0;
      }
    }

    if (daysToAdd == 0 && _selectedProstheticTypeId != null) {
      final selectedType = _prostheticTypesList.firstWhere(
        (e) => e['id'] == _selectedProstheticTypeId,
        orElse: () => null,
      );
      if (selectedType != null) {
        daysToAdd = selectedType['expected_days'] ?? selectedType['days'] ?? 3;
      }
    }

    if (daysToAdd > 0) {
      final expectedDate = DateTime.now().add(Duration(days: daysToAdd));
      _deliveryDateController.text = expectedDate.toString().split(' ')[0];
    }
  }

  Future<void> _selectDeliveryDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initial = _deliveryDateController.text.isNotEmpty
        ? DateTime.tryParse(_deliveryDateController.text) ?? now
        : now;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: Directionality(
            textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _deliveryDateController.text = pickedDate.toString().split(' ')[0];
      });
    }
  }

  void _selectSessionTime(BuildContext context) {
    TimeOfDay initialTime = TimeOfDay.now();
    if (_sessionTimeController.text.isNotEmpty) {
      final parts = _sessionTimeController.text.split(':');
      if (parts.length == 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? initialTime.hour,
          minute: int.tryParse(parts[1]) ?? initialTime.minute,
        );
      }
    }

    TimeOfDay tempTime = initialTime;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Directionality(
          textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            height: 300,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          _t('cancel'),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Text(
                        _t('session_time_picker'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final String hour = tempTime.hour.toString().padLeft(
                            2,
                            '0',
                          );
                          final String minute = tempTime.minute
                              .toString()
                              .padLeft(2, '0');
                          setState(() {
                            _sessionTimeController.text = '$hour:$minute';
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          _t('confirm'),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.hms,
                    initialTimerDuration: Duration(
                      hours: initialTime.hour,
                      minutes: initialTime.minute,
                    ),
                    onTimerDurationChanged: (Duration newDuration) {
                      tempTime = TimeOfDay(
                        hour: newDuration.inHours % 24,
                        minute: newDuration.inMinutes % 60,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectionBottomSheet({
    required String title,
    required List<dynamic> items,
    required dynamic selectedValue,
    required String Function(dynamic) itemLabel,
    required Function(dynamic) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Directionality(
          textDirection: _isRTL ? TextDirection.rtl : TextDirection.ltr,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.6,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200, height: 1),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = item['id'] == selectedValue;
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        tileColor: isSelected
                            ? AppColors.primary.withOpacity(0.08)
                            : Colors.transparent,
                        title: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textDark,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              )
                            : null,
                        onTap: () {
                          onSelect(item['id']);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onProstheticTypeChanged(dynamic typeId) {
    setState(() {
      _selectedProstheticTypeId = typeId;
      _selectedStartStageId = null;
      _stagesList = [];

      final selectedObj = _prostheticTypesList.firstWhere(
        (element) => element['id'] == typeId,
        orElse: () => null,
      );

      if (selectedObj != null && selectedObj['stages'] != null) {
        _stagesList = selectedObj['stages'] as List<dynamic>;
      }

      _calculateExpectedDeliveryDate();
    });
  }

  Future<bool> _confirmEmptyField(String fieldName) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              _t('reminder'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(_tArgs('confirm_empty_field', {'field': fieldName})),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(_t('edit_field')),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  _t('continue_btn'),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSnackBar(String text, Color bg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: bg,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final rawPatientName = _patientController.text.trim();
    final rawPatientNumber = _patientNumberController.text.trim();

    if (rawPatientName.isEmpty && rawPatientNumber.isEmpty) {
      _showSnackBar(_t('enter_patient_name_or_number'), Colors.orange);
      return;
    }

    final String finalPatientName = rawPatientName.isNotEmpty
        ? rawPatientName
        : _tArgs('patient_number_prefix', {'number': rawPatientNumber});

    if (_selectedDoctorId == null || _selectedProstheticTypeId == null) {
      _showSnackBar(_t('select_doctor_and_prosthetic'), Colors.orange);
      return;
    }

    if (_shadeController.text.trim().isEmpty) {
      bool confirmShade = await _confirmEmptyField(_t('shade_field'));
      if (!confirmShade) return;
    }

    if (_uploadedImagePath == null && _selectedImage == null) {
      bool confirmImage = await _confirmEmptyField(_t('prosthetic_image'));
      if (!confirmImage) return;
    }

    if (_isUploadingImage) {
      _showSnackBar(_t('wait_for_image_upload'), Colors.orange);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final body = {
        'doctor_id': _selectedDoctorId,
        'prosthetic_type_id': _selectedProstheticTypeId,
        'start_stage_id': _selectedStartStageId,
        'patient_name': finalPatientName,
        'patient_number': rawPatientNumber,
        'xml_number': _xmlNumberController.text.trim(),
        'shade': _shadeController.text.trim(),
        'delivery_date': _deliveryDateController.text,
        'session_time': _sessionTimeController.text.trim().isNotEmpty
            ? _sessionTimeController.text.trim()
            : null,
        'image_path': _uploadedImagePath,
        'notes': _additionalNotesController.text.trim(),
        'status': 'received',
      };

      final response = await ApiService.post(ApiConstants.clinicOrders, body);

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        _showSnackBar(_t('order_added_success'), Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(
          '${_t("add_failed")} (${response.statusCode}): ${response.body}',
          Colors.red,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${_t("connection_error")}: $e', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _t('create_order_title'),
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionCard(
                      title: _t('basic_info'),
                      icon: Icons.person_outline,
                      children: [
                        _buildLabel('${_t("doctor")} *'),
                        _buildCustomSelectTile(
                          hint: _t('select_doctor'),
                          value: _selectedDoctorId != null
                              ? _doctorsList.firstWhere(
                                  (d) => d['id'] == _selectedDoctorId,
                                  orElse: () => {},
                                )['name']
                              : null,
                          onTap: () {
                            _showSelectionBottomSheet(
                              title: _t('select_doctor'),
                              items: _doctorsList,
                              selectedValue: _selectedDoctorId,
                              itemLabel: (doc) => doc['name'] ?? '',
                              onSelect: (val) {
                                setState(() => _selectedDoctorId = val);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(_t('patient_name')),
                                  _buildTextField(
                                    _patientController,
                                    _t('enter_patient_name'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel(_t('patient_number')),
                                  _buildTextField(
                                    _patientNumberController,
                                    '1234',
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildLabel(_t('xml_number')),
                        _buildTextField(
                          _xmlNumberController,
                          _t('enter_xml_number'),
                        ),
                        const SizedBox(height: 12),
                        _buildLabel('${_t("prosthetic_type")} *'),
                        _buildCustomSelectTile(
                          hint: _t('select_prosthetic_type'),
                          value: _selectedProstheticTypeId != null
                              ? _prostheticTypesList.firstWhere(
                                  (p) => p['id'] == _selectedProstheticTypeId,
                                  orElse: () => {},
                                )['name']
                              : null,
                          onTap: () {
                            _showSelectionBottomSheet(
                              title: _t('select_prosthetic_type'),
                              items: _prostheticTypesList,
                              selectedValue: _selectedProstheticTypeId,
                              itemLabel: (type) =>
                                  type['name']?.toString() ?? '',
                              onSelect: (val) {
                                _onProstheticTypeChanged(val);
                              },
                            );
                          },
                        ),
                        if (_stagesList.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildLabel(_t('start_stage')),
                          _buildCustomSelectTile(
                            hint: _t('select_start_stage'),
                            value: _selectedStartStageId != null
                                ? _stagesList.firstWhere(
                                    (s) => s['id'] == _selectedStartStageId,
                                    orElse: () => {},
                                  )['name']
                                : null,
                            onTap: () {
                              _showSelectionBottomSheet(
                                title: _t('select_start_stage'),
                                items: _stagesList,
                                selectedValue: _selectedStartStageId,
                                itemLabel: (stage) =>
                                    stage['name']?.toString() ?? '',
                                onSelect: (val) {
                                  setState(() {
                                    _selectedStartStageId = val;
                                    _calculateExpectedDeliveryDate();
                                  });
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: _t('dates_times'),
                      icon: Icons.calendar_today_outlined,
                      children: [
                        _buildDateTimeCard(
                          title: _t('order_date'),
                          value: _orderDateController.text,
                          icon: Icons.calendar_today,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimeCard(
                          title: _t('delivery_date'),
                          value: _deliveryDateController.text.isNotEmpty
                              ? _deliveryDateController.text
                              : _t('select_date'),
                          icon: Icons.event_available,
                          color: Colors.green,
                          onTap: () => _selectDeliveryDate(context),
                        ),
                        const SizedBox(height: 10),
                        _buildDateTimeCard(
                          title: _t('session_time'),
                          value: _sessionTimeController.text.isNotEmpty
                              ? _sessionTimeController.text
                              : _t('select_session_time_hint'),
                          icon: Icons.access_time_filled,
                          color: Colors.orange,
                          onTap: () => _selectSessionTime(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: _t('prosthetic_details_image'),
                      icon: Icons.palette_outlined,
                      children: [
                        _buildLabel(_t('shade')),
                        _buildTextField(_shadeController, _t('shade_example')),
                        const SizedBox(height: 12),
                        _buildLabel(_t('prosthetic_image')),
                        _buildImageUploader(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: _t('additional_notes'),
                      icon: Icons.note_alt_outlined,
                      children: [
                        _buildTextField(
                          _additionalNotesController,
                          _t('type_notes_hint'),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submitOrder,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _t('save_and_add_order'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCustomSelectTile({
    required String hint,
    required String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                value ?? hint,
                style: TextStyle(
                  fontSize: 13,
                  color: value != null ? AppColors.textDark : Colors.grey,
                  fontWeight: value != null
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    final placeholderKeywords = [
      _t('select_date'),
      _t('select_session_time_hint'),
      'اختر',
      'حدد',
    ];

    final isPlaceholder = placeholderKeywords.any((k) => value.contains(k));

    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: onTap != null && isPlaceholder
                              ? Colors.grey.shade600
                              : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: color.withOpacity(0.7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploader() {
    return InkWell(
      onTap: _isUploadingImage ? null : _showImagePickerModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: _isUploadingImage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                    strokeWidth: 2,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _t('uploading_image'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              )
            : _selectedImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                            _uploadedImagePath = null;
                          });
                        },
                      ),
                    ),
                  ),
                  if (_uploadedImagePath != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${_t("uploaded_label")}: $_uploadedImagePath',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _t('image_upload_hint'),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: _buildInputDecoration(hint: hint),
    );
  }
}
