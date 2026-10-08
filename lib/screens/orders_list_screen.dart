import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';
import 'order_details_screen.dart';

class OrdersListScreen extends StatefulWidget {
  const OrdersListScreen({super.key});

  @override
  State<OrdersListScreen> createState() => _OrdersListScreenState();
}

class _OrdersListScreenState extends State<OrdersListScreen> {
  List<dynamic> _allOrders = [];
  List<dynamic> _filteredOrders = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;
  String get _currentLang => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConstants.clinicOrders);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            if (data is List) {
              _allOrders = data;
            } else if (data is Map && data.containsKey('data')) {
              _allOrders = data['data'] ?? [];
            } else {
              _allOrders = [];
            }
            _applyFilterAndSearch();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndSearch() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      _filteredOrders = _allOrders.where((order) {
        final status = (order['status'] ?? '').toString().toLowerCase();
        final patientName = (order['patient_name'] ?? '')
            .toString()
            .toLowerCase();

        bool matchesFilter =
            _selectedFilter == 'all' || status == _selectedFilter;
        bool matchesSearch =
            query.isEmpty ||
            patientName.contains(query) ||
            order['id'].toString().contains(query);

        return matchesFilter && matchesSearch;
      }).toList();

      _filteredOrders.sort((a, b) {
        final dateAStr = a['delivery_date']?.toString();
        final dateBStr = b['delivery_date']?.toString();

        if (dateAStr == null || dateAStr.isEmpty) return 1;
        if (dateBStr == null || dateBStr.isEmpty) return -1;

        final dateA = DateTime.tryParse(dateAStr);
        final dateB = DateTime.tryParse(dateBStr);

        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateA.compareTo(dateB);
      });
    });
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
        return const Color(0xFFEF4444);
      case 'needs_redo':
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
        return Icons.replay_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _getStatusTranslation(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return '';
    final key = 'status_${rawStatus.toLowerCase().trim()}';
    final translated = _loc?.translate(key);
    return (translated != null && translated != key) ? translated : rawStatus;
  }

  String _getProstheticTypeName(dynamic prostheticType) {
    final defaultText = _t('dental_prosthesis');

    if (prostheticType == null) return defaultText;
    var nameData = prostheticType['name'];

    if (nameData is String) {
      try {
        nameData = jsonDecode(nameData);
      } catch (_) {
        return nameData;
      }
    }

    if (nameData is Map) {
      return nameData[_currentLang] ??
          nameData['ar'] ??
          nameData['en'] ??
          nameData['de'] ??
          defaultText;
    }

    return nameData.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _t('nav_orders'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFFE2E8F0),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _searchFocusNode.hasFocus
                      ? AppColors.primary.withOpacity(0.5)
                      : const Color(0xFFE2E8F0),
                  width: _searchFocusNode.hasFocus ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _searchFocusNode.hasFocus
                        ? AppColors.primary.withOpacity(0.10)
                        : Colors.black.withOpacity(0.02),
                    blurRadius: _searchFocusNode.hasFocus ? 16 : 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => _applyFilterAndSearch(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: _t('search_orders_hint'),
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.normal,
                  ),
                  prefixIcon: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF64748B),
                              size: 14,
                            ),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilterAndSearch();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildFilterChip(_t('filter_all'), 'all', Icons.apps_rounded),
                  _buildFilterChip(
                    _getStatusTranslation('pending'),
                    'pending',
                    Icons.hourglass_empty_rounded,
                  ),
                  _buildFilterChip(
                    _getStatusTranslation('in_progress'),
                    'in_progress',
                    Icons.autorenew_rounded,
                  ),
                  _buildFilterChip(
                    _getStatusTranslation('needs_redo'),
                    'needs_redo',
                    Icons.replay_rounded,
                  ),
                  _buildFilterChip(
                    _getStatusTranslation('completed'),
                    'completed',
                    Icons.task_alt_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchOrders,
                color: AppColors.primary,
                backgroundColor: Colors.white,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2.5,
                        ),
                      )
                    : _filteredOrders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, index) {
                          final item = _filteredOrders[index];
                          final status = item['status'] ?? 'pending';
                          final statusColor = _getStatusColor(status);
                          final prostheticName = _getProstheticTypeName(
                            item['prosthetic_type'],
                          );

                          return _buildOrderCard(
                            item: item,
                            status: status,
                            statusColor: statusColor,
                            prostheticName: prostheticName,
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard({
    required dynamic item,
    required String status,
    required Color statusColor,
    required String prostheticName,
  }) {
    final bool isRtl = _currentLang == 'ar';
    final statusIcon = _getStatusIcon(status);

    final String patientName = (item['patient_name'] ?? '').toString().trim();
    final String avatarLetter = patientName.isNotEmpty
        ? patientName.substring(0, 1).toUpperCase()
        : '?';

    String stageName = _t('unspecified');
    if (item['stage_name'] != null) {
      stageName = item['stage_name'].toString();
    } else if (item['stages'] is List && (item['stages'] as List).isNotEmpty) {
      final lastStage = (item['stages'] as List).last;
      stageName =
          lastStage['stage_name'] ??
          (lastStage['stage_type'] is Map
              ? lastStage['stage_type']['name']
              : lastStage['stage_type']) ??
          stageName;
    }

    final bool isBilled =
        item['is_billed'] == true ||
        item['is_billed'] == 1 ||
        item['invoice'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            splashColor: statusColor.withOpacity(0.05),
            highlightColor: statusColor.withOpacity(0.03),
            onTap: () async {
              final res = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(orderId: item['id']),
                ),
              );
              if (res == true) _fetchOrders();
            },
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: isRtl ? 0 : null,
                  left: isRtl ? null : 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [statusColor, statusColor.withOpacity(0.55)],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isRtl ? 16 : 20,
                    16,
                    isRtl ? 20 : 16,
                    16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary.withOpacity(0.15),
                                        AppColors.primary.withOpacity(0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    avatarLetter,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    patientName.isNotEmpty
                                        ? patientName
                                        : _t('unnamed_patient'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Color(0xFF0F172A),
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBilled) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF0EA5E9,
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF0EA5E9,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.receipt_long_rounded,
                                        size: 13,
                                        color: Color(0xFF0EA5E9),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        _t('billed'),
                                        style: const TextStyle(
                                          color: Color(0xFF0EA5E9),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
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
                                    Icon(
                                      statusIcon,
                                      size: 14,
                                      color: statusColor,
                                    ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF1F5F9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.medical_services_outlined,
                              color: AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prostheticName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF334155),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  if (stageName.isNotEmpty &&
                                      stageName.toLowerCase() !=
                                          'unspecified' &&
                                      stageName != _t('unspecified'))
                                    Row(
                                      children: [
                                        Text(
                                          '${_t("stage")}: ',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF94A3B8),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            stageName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${item['id']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (item['delivery_date'] != null)
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  item['delivery_date'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isRtl
                                  ? Icons.arrow_back_ios_rounded
                                  : Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.85),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () {
              setState(() {
                _selectedFilter = value;
                _applyFilterAndSearch();
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.10),
                          AppColors.primary.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.12),
                          AppColors.primary.withOpacity(0.06),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      size: 46,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                _t('no_orders_found'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _t('try_changing_search'),
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
