import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:profil_Smile/core/services/storage_service.dart';
import 'dart:ui' as ui;
import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';

class OrderDetailsScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  bool _isSubmitting = false;

  // اختيار صورة جديدة لتعديلها
  File? _selectedNewImage;
  final ImagePicker _picker = ImagePicker();

  // Controllers لتعديل بيانات الطلب
  final TextEditingController _patientNameController = TextEditingController();
  final TextEditingController _patientNumberController =
      TextEditingController();
  final TextEditingController _xmlNumberController = TextEditingController();
  final TextEditingController _shadeController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final TextEditingController _sessionTimeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final TextEditingController _redoNotesController = TextEditingController();

  // ═══════════════════════════════════════════════
  // Translation Helpers
  // ═══════════════════════════════════════════════
  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;
  String _tArgs(String key, Map<String, String> args) =>
      _loc?.translateWithArgs(key, args) ?? key;
  String get _currentLang => Localizations.localeOf(context).languageCode;
  bool get _isRTL => _currentLang == 'ar';

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _patientNumberController.dispose();
    _xmlNumberController.dispose();
    _shadeController.dispose();
    _deliveryDateController.dispose();
    _sessionTimeController.dispose();
    _notesController.dispose();
    _redoNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.get(
        '${ApiConstants.clinicOrders}/${widget.orderId}',
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final fetchedData = data['data'] ?? data;

        setState(() {
          _orderData = fetchedData;

          _patientNameController.text =
              fetchedData['patient_name']?.toString() ?? '';
          _patientNumberController.text =
              fetchedData['patient_number']?.toString() ?? '';
          _xmlNumberController.text =
              fetchedData['xml_number']?.toString() ?? '';
          _shadeController.text = fetchedData['shade']?.toString() ?? '';
          _deliveryDateController.text =
              fetchedData['delivery_date']?.toString() ?? '';
          _sessionTimeController.text =
              fetchedData['session_time']?.toString() ?? '';
          _notesController.text = fetchedData['notes']?.toString() ?? '';

          _selectedNewImage = null;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // عرض الصورة بحجم كامل
  void _showFullScreenImage({String? imageUrl, File? imageFile}) {
    if (imageUrl == null && imageFile == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageFile != null
                    ? Image.file(imageFile)
                    : Image.network(
                        imageUrl!,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.white,
                            ),
                      ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                style: IconButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // اختيار تاريخ التسليم
  Future<void> _selectDeliveryDate() async {
    DateTime initialDate = DateTime.now();

    if (_deliveryDateController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_deliveryDateController.text);
      } catch (_) {}
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              headerBackgroundColor: AppColors.primary,
              headerForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: Directionality(
            textDirection: _isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _deliveryDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // اختيار وقت الجلسة
  Future<void> _selectSessionTime() async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (_sessionTimeController.text.isNotEmpty) {
      try {
        final parts = _sessionTimeController.text.split(':');
        if (parts.length >= 2) {
          initialTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        }
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              hourMinuteColor: const Color(0xFFF1F5F9),
              hourMinuteTextColor: AppColors.primary,
              dialHandColor: AppColors.primary,
              dialBackgroundColor: const Color(0xFFF8FAFC),
            ),
          ),
          child: Directionality(
            textDirection: _isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            child: child!,
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        final dt = DateTime(
          now.year,
          now.month,
          now.day,
          picked.hour,
          picked.minute,
        );
        _sessionTimeController.text = DateFormat('HH:mm').format(dt);
      });
    }
  }

  // اختيار صورة جديدة
  Future<void> _pickNewImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedNewImage = File(pickedFile.path);
        });
      }
    } catch (e) {}
  }

  // اختيار طريقة الرفع (كاميرا / معرض)
  void _showImagePickerModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              onTap: () {
                Navigator.pop(ctx);
                _pickNewImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: AppColors.primary,
              ),
              title: Text(_t('camera')),
              onTap: () {
                Navigator.pop(ctx);
                _pickNewImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic>? _getFieldHistory(String fieldName) {
    if (_orderData == null || _orderData!['histories'] == null) return null;
    final histories = _orderData!['histories'] as List<dynamic>;
    try {
      return histories.firstWhere(
        (h) => h['field_name'] == fieldName,
        orElse: () => null,
      );
    } catch (_) {
      return null;
    }
  }

  /// حفظ كافة التعديلات النصية + الصورة الجديدة إن وجِدت
  Future<void> _saveOrderChanges() async {
    setState(() => _isSubmitting = true);
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('${ApiConstants.clinicOrders}/${widget.orderId}');

      var request = http.MultipartRequest('POST', uri);
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      request.fields['_method'] = 'PUT';
      request.fields['patient_name'] = _patientNameController.text.trim();
      request.fields['patient_number'] = _patientNumberController.text.trim();
      request.fields['xml_number'] = _xmlNumberController.text.trim();
      request.fields['shade'] = _shadeController.text.trim();
      request.fields['delivery_date'] = _deliveryDateController.text.trim();
      request.fields['session_time'] = _sessionTimeController.text.trim();
      request.fields['notes'] = _notesController.text.trim();

      if (_selectedNewImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedNewImage!.path),
        );
      }

      final streamedResponse = await request.send();
      final res = await http.Response.fromStream(streamedResponse);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('changes_saved_success')),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchOrderDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_t("changes_save_failed")}: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // اعتماد المرحلة الحالية
  Future<void> _approveStage(int stageId) async {
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.post(
        '${ApiConstants.clinicOrders}/${widget.orderId}/approve-stage',
        {'stage_id': stageId},
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('stage_approved_success')),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _fetchOrderDetails();
      } else {
        if (mounted) {
          final data = jsonDecode(res.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? _t('stage_approve_failed')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showRedoDialog(int stageId) {
    _redoNotesController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t('redo_stage_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('redo_stage_hint'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _redoNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _t('enter_notes_hint'),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              if (_redoNotesController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_t('enter_redo_reason')),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              _rejectStageWithNotes(stageId, _redoNotesController.text.trim());
            },
            child: Text(
              _t('confirm_redo'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectStageWithNotes(int stageId, String notes) async {
    setState(() => _isSubmitting = true);
    try {
      final res = await ApiService.post(
        '${ApiConstants.clinicOrders}/${widget.orderId}/repeat-stage',
        {
          'stage_id': stageId,
          'notes': notes,
          'expected_delivery_date': DateFormat(
            'yyyy-MM-dd',
          ).format(DateTime.now().add(const Duration(days: 2))),
        },
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_t('redo_request_sent_with_notes')),
              backgroundColor: Colors.orange,
            ),
          );
        }
        await _fetchOrderDetails();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_t("generic_error")}: ${res.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatDate(String? rawDate, String locale) {
    if (rawDate == null || rawDate.isEmpty) return '';
    try {
      DateTime parsed = DateTime.parse(rawDate);
      return DateFormat('yyyy-MM-dd HH:mm', locale).format(parsed);
    } catch (_) {
      return rawDate;
    }
  }

  String _getStageName(
    dynamic stageType,
    dynamic stageData,
    String currentLang,
  ) {
    if (stageData != null && stageData['stage_name'] != null) {
      return stageData['stage_name'].toString();
    }
    if (stageType == null) return '';
    var nameData = stageType['name'];
    if (nameData is String) {
      try {
        nameData = jsonDecode(nameData);
      } catch (_) {
        return nameData;
      }
    }
    if (nameData is Map) {
      return nameData[currentLang] ??
          nameData['ar'] ??
          nameData['en'] ??
          nameData['de'] ??
          '';
    }
    return nameData.toString();
  }

  String? _getPrimaryOrderImageUrl() {
    if (_orderData == null) return null;

    String? url;

    if (_orderData!['image_url'] != null &&
        _orderData!['image_url'].toString().isNotEmpty) {
      url = _orderData!['image_url'].toString();
      if (url.contains('/storage/storage/')) {
        url = url.replaceFirst('/storage/storage/', '/storage/');
      }
    } else {
      final rawPath = _orderData!['image_path']?.toString();
      if (rawPath != null && rawPath.isNotEmpty) {
        if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
          url = rawPath;
        } else {
          String cleanPath = rawPath.startsWith('/')
              ? rawPath.substring(1)
              : rawPath;
          String rootUrl = ApiConstants.baseUrl.replaceAll('/api', '');
          if (rootUrl.endsWith('/')) {
            rootUrl = rootUrl.substring(0, rootUrl.length - 1);
          }
          url = '$rootUrl/$cleanPath';
        }
      }
    }

    if (url == null) return null;

    final updatedAt =
        _orderData!['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
    return '$url?v=$updatedAt';
  }

  String? _getImageUrl(Map<String, dynamic>? stage) {
    if (stage == null) return null;

    if (stage['image_url'] != null &&
        stage['image_url'].toString().isNotEmpty) {
      return stage['image_url'].toString();
    }

    final rawPath = stage['image_path']?.toString();
    if (rawPath == null || rawPath.isEmpty) return null;

    if (rawPath.startsWith('http://') || rawPath.startsWith('https://')) {
      return rawPath;
    }

    String cleanPath = rawPath.startsWith('/') ? rawPath.substring(1) : rawPath;

    String rootUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    if (rootUrl.endsWith('/')) {
      rootUrl = rootUrl.substring(0, rootUrl.length - 1);
    }

    return '$rootUrl/$cleanPath';
  }

  String _getStatusTranslation(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return '';
    final key = 'status_${rawStatus.toLowerCase().trim()}';
    final translated = _loc?.translate(key);
    return (translated != null && translated != key) ? translated : rawStatus;
  }

  Color _getStatusColor(String? rawStatus) {
    if (rawStatus == null) return const Color(0xFF64748B);

    switch (rawStatus.toLowerCase().trim()) {
      case 'received':
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'approved':
      case 'completed':
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'needs_redo':
      case 'redo_requested':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getStatusIcon(String? rawStatus) {
    if (rawStatus == null) return Icons.info_outline;

    switch (rawStatus.toLowerCase().trim()) {
      case 'received':
        return Icons.inbox_rounded;
      case 'pending':
        return Icons.hourglass_empty_rounded;
      case 'in_progress':
        return Icons.autorenew_rounded;
      case 'approved':
        return Icons.check_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'needs_redo':
      case 'redo_requested':
      case 'rejected':
        return Icons.replay_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final status = _orderData?['status'] ?? 'received';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    final List<dynamic> rawStages = _orderData?['stages'] is List
        ? List.from(_orderData!['stages'])
        : [];

    rawStages.sort((a, b) {
      int idA = a['id'] ?? 0;
      int idB = b['id'] ?? 0;
      return idA.compareTo(idB);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          '${_t('order_details')} #${widget.orderId}',
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E293B)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══ 1. كارت بيانات الطلب + الصورة + التعديلات ═══
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _t('order_patient_data'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          if (_orderData?['invoice'] != null &&
                              _orderData!['invoice'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.receipt_long_rounded,
                                    size: 14,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _t('invoiced'),
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 14, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusTranslation(status),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_orderData?['doctor'] != null) ...[
                    Text(
                      '${_t('doctor')}: ${_orderData!['doctor']['name']}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // قسم صورة الطلب
                  _buildOrderImageSection(),

                  const SizedBox(height: 12),

                  // الحقول القابلة للتعديل
                  _buildEditableField(
                    _t('patient_name'),
                    'patient_name',
                    _patientNameController,
                  ),
                  _buildEditableField(
                    _t('patient_number'),
                    'patient_number',
                    _patientNumberController,
                  ),
                  _buildEditableField(
                    _t('xml_number'),
                    'xml_number',
                    _xmlNumberController,
                  ),
                  _buildEditableField(_t('shade'), 'shade', _shadeController),

                  // اختيار تاريخ التسليم
                  _buildPickerField(
                    label: _t('delivery_session_date'),
                    fieldName: 'delivery_date',
                    controller: _deliveryDateController,
                    icon: Icons.calendar_today_rounded,
                    onTap: _selectDeliveryDate,
                  ),

                  // اختيار وقت الجلسة
                  _buildPickerField(
                    label: _t('session_time'),
                    fieldName: 'session_time',
                    controller: _sessionTimeController,
                    icon: Icons.access_time_rounded,
                    onTap: _selectSessionTime,
                  ),

                  _buildEditableField(
                    _t('notes'),
                    'notes',
                    _notesController,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),

                  // زر حفظ التعديلات
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _saveOrderChanges,
                      icon: const Icon(
                        Icons.save_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _t('save_data_and_image_changes'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ═══ 2. مراحل التصنيع ═══
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _t('lab_production_stages'),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${_t('stages')} (${rawStages.length})',
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (rawStages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    _t('no_stages_registered'),
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rawStages.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final stage = Map<String, dynamic>.from(rawStages[index]);
                  final stageType = stage['stage_type'];
                  final stageName = _getStageName(
                    stageType,
                    stage,
                    _currentLang,
                  );
                  final finalImageUrl = _getImageUrl(stage);

                  final stageRawStatus =
                      stage['approval_status']?.toString() ??
                      stage['status']?.toString();
                  final stageColor = _getStatusColor(stageRawStatus);
                  final stageIcon = _getStatusIcon(stageRawStatus);

                  bool showStageActions =
                      stageRawStatus?.toLowerCase() != 'approved' &&
                      stageRawStatus?.toLowerCase() != 'rejected' &&
                      status != 'delivered' &&
                      status != 'cancelled';

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_t('stage')} ${index + 1}',
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      stageName.isNotEmpty
                                          ? stageName
                                          : _tArgs('stage_number', {
                                              'number': '${index + 1}',
                                            }),
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _t('status'),
                                    style: const TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: stageColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: stageColor.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          stageIcon,
                                          size: 16,
                                          color: stageColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            _getStatusTranslation(
                                              stageRawStatus,
                                            ),
                                            style: TextStyle(
                                              color: stageColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        Text(
                          _t('stage_image'),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (finalImageUrl != null)
                          GestureDetector(
                            onTap: () =>
                                _showFullScreenImage(imageUrl: finalImageUrl),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    finalImageUrl,
                                    width: double.infinity,
                                    height: 220,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const SizedBox.shrink(),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fullscreen_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          _buildImagePlaceholder(height: 120),

                        if (showStageActions) ...[
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFE2E8F0)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _approveStage(stage['id'] ?? 0),
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _t('approve_and_next_stage'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEF4444),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _showRedoDialog(stage['id'] ?? 0),
                                  icon: const Icon(
                                    Icons.replay_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _t('redo_stage_with_note'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderImageSection() {
    final primaryImageUrl = _getPrimaryOrderImageUrl();
    final imageHistory = _getFieldHistory('image_path');
    final hasImage = _selectedNewImage != null || primaryImageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _t('order_image_title'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Row(
              children: [
                if (hasImage)
                  IconButton(
                    icon: const Icon(
                      Icons.zoom_in_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _showFullScreenImage(
                      imageUrl: primaryImageUrl,
                      imageFile: _selectedNewImage,
                    ),
                    tooltip: _t('view_full_size'),
                  ),
                TextButton.icon(
                  onPressed: _showImagePickerModal,
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    hasImage ? _t('change_image') : _t('add_image'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: hasImage
              ? () => _showFullScreenImage(
                  imageUrl: primaryImageUrl,
                  imageFile: _selectedNewImage,
                )
              : null,
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _selectedNewImage != null
                    ? Image.file(
                        _selectedNewImage!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      )
                    : (primaryImageUrl != null
                          ? Image.network(
                              primaryImageUrl,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder()),
              ),
              if (hasImage)
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (imageHistory != null) ...[
          const SizedBox(height: 6),
          Text(
            _tArgs('image_modified_on', {
              'date': _formatDate(
                imageHistory['date'] ?? imageHistory['created_at'],
                _currentLang,
              ),
            }),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFD97706),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPickerField({
    required String label,
    required String fieldName,
    required TextEditingController controller,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final history = _getFieldHistory(fieldName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: IgnorePointer(
              child: TextField(
                controller: controller,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon: Icon(icon, color: AppColors.primary, size: 20),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ),
          if (history != null) ...[
            const SizedBox(height: 4),
            Text(
              _tArgs('data_modified_on', {
                'date': _formatDate(
                  history['date'] ?? history['created_at'],
                  _currentLang,
                ),
                'old': history['old_value'] ?? _t('empty'),
                'new': history['new_value'] ?? _t('empty'),
              }),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    String fieldName,
    TextEditingController controller, {
    int maxLines = 1,
  }) {
    final history = _getFieldHistory(fieldName);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          if (history != null) ...[
            const SizedBox(height: 4),
            Text(
              _tArgs('data_modified_on', {
                'date': _formatDate(
                  history['date'] ?? history['created_at'],
                  _currentLang,
                ),
                'old': history['old_value'] ?? _t('empty'),
                'new': history['new_value'] ?? _t('empty'),
              }),
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder({double height = 200}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.image_not_supported_outlined,
            size: 42,
            color: Color(0xFF94A3B8),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _t('no_image_attached'),
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
