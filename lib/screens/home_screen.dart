import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:profil_Smile/core/services/notification_service.dart';
import 'package:profil_Smile/screens/notifications_screen.dart';
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';
import '../providers/locale_provider.dart';
import 'ClinicProfileScreen.dart';
import 'Statistics_screen.dart';
import 'orders_list_screen.dart';
import 'create_order_screen.dart';
import 'order_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    String tr(String key) => loc?.translate(key) ?? key;

    final List<Widget> pages = [
      _HomeTab(onNavigateToOrders: () => setState(() => _currentIndex = 1)),
      const OrdersListScreen(),
      const ClinicTab(),
      const StatisticsTab(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textLight,
        showUnselectedLabels: true,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: tr('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.assignment_outlined),
            label: tr('nav_orders'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_hospital_outlined),
            label: tr('nav_clinic'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_rounded),
            label: tr('nav_statistics'),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final VoidCallback onNavigateToOrders;
  const _HomeTab({required this.onNavigateToOrders});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;
  String _tArgs(String key, Map<String, String> args) =>
      _loc?.translateWithArgs(key, args) ?? key;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOrders();
    });
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
              _orders = data;
            } else if (data is Map && data.containsKey('data')) {
              _orders = data['data'] ?? [];
            } else {
              _orders = [];
            }

            _orders.sort((a, b) {
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final currentLocale = context.read<LocaleProvider>().locale;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.language, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _t('select_language'),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangTile(
                dialogContext,
                currentLocale,
                'ar',
                '🇸🇾',
                'العربية',
              ),
              const Divider(),
              _buildLangTile(
                dialogContext,
                currentLocale,
                'en',
                '🇬🇧',
                'English',
              ),
              const Divider(),
              _buildLangTile(
                dialogContext,
                currentLocale,
                'de',
                '🇩🇪',
                'Deutsch',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLangTile(
    BuildContext dialogContext,
    Locale? currentLocale,
    String code,
    String flag,
    String label,
  ) {
    final isSelected = currentLocale?.languageCode == code;
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 22)),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : null,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        context.read<LocaleProvider>().setLocale(Locale(code));
        Navigator.pop(dialogContext);
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetchOrders,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // الهيدر العلوي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // زر اللغة
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.language_rounded,
                          color: AppColors.primary,
                        ),
                        onPressed: () => _showLanguageDialog(context),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // ✅ زر الإشعارات مع Badge تفاعلي
                    ValueListenableBuilder<int>(
                      valueListenable: NotificationService.unreadCountNotifier,
                      builder: (context, unreadCount, _) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (unreadCount > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      unreadCount > 99 ? '99+' : '$unreadCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _t('welcome_back'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                    Text(
                      _t('doctor_title'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // الكارت الرئيسي
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF14C8B0), Color(0xFF0EA28E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
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
                              _t('manage_lab_orders'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _t('add_new_prosthetic_subtitle'),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.biotech_rounded,
                        size: 44,
                        color: Colors.white38,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CreateOrderScreen(),
                          ),
                        );
                        if (result == true) {
                          _fetchOrders();
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _t('add_order_btn'),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.add, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // عنوان أحدث الطلبات
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _t('recent_orders'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                InkWell(
                  onTap: widget.onNavigateToOrders,
                  child: Text(
                    _tArgs('view_all_with_count', {
                      'count': '${_orders.length}',
                    }),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // القائمة المصغرة
            _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : _orders.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_rounded,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _t('no_orders_found'),
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orders.length > 5 ? 5 : _orders.length,
                    itemBuilder: (context, index) {
                      final item = _orders[index];
                      final status = item['status'] ?? 'pending';
                      final int orderId = item['id'] ?? 0;

                      final statusColor = _getStatusColor(status);
                      final statusIcon = _getStatusIcon(status);

                      return InkWell(
                        onTap: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OrderDetailsScreen(orderId: orderId),
                            ),
                          );
                          if (res == true) _fetchOrders();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.accentMint,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.medical_services_outlined,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['patient_name'] ??
                                          _t('order_placeholder'),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['prosthetic_type']?['name']
                                              ?.toString() ??
                                          _t('dental_prosthesis'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
