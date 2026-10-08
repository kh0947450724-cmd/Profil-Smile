import 'dart:convert';
import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../core/localization/app_localizations.dart';
import '../core/services/api_service.dart';
import '../core/theme/app_theme.dart';

class StatisticsTab extends StatefulWidget {
  const StatisticsTab({super.key});

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  bool _isLoading = true;

  int _totalOrders = 0;
  int _deliveredOrders = 0;
  int _inProductionOrders = 0;
  int _receivedOrders = 0;
  int _pendingOrders = 0;

  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final response = await ApiService.get(ApiConstants.clinicOrders);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        List<dynamic> orders = [];
        int totalFromApi = 0;

        if (data is Map && data.containsKey('data')) {
          orders = data['data'] ?? [];
          if (data.containsKey('meta') && data['meta'] != null) {
            totalFromApi = data['meta']['total'] ?? orders.length;
          } else {
            totalFromApi = orders.length;
          }
        } else if (data is List) {
          orders = data;
          totalFromApi = orders.length;
        }

        int delivered = 0;
        int inProduction = 0;
        int received = 0;
        int pending = 0;

        for (var item in orders) {
          final status = (item['status'] ?? '').toString().trim().toLowerCase();

          if (status == 'delivered') {
            delivered++;
          } else if (status == 'in_production' || status == 'in-production') {
            inProduction++;
          } else if (status == 'received') {
            received++;
          } else if (status == 'pending') {
            pending++;
          }
        }

        if (mounted) {
          setState(() {
            _totalOrders = totalFromApi;
            _deliveredOrders = delivered;
            _inProductionOrders = inProduction;
            _receivedOrders = received;
            _pendingOrders = pending;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchStatistics,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('clinic_statistics'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _t('statistics_subtitle'),
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
            const SizedBox(height: 20),
            _buildTotalCard(title: _t('total_orders')),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _buildStatCard(
                  title: _t('status_delivered'),
                  count: _deliveredOrders,
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildStatCard(
                  title: _t('status_in_production'),
                  count: _inProductionOrders,
                  icon: Icons.precision_manufacturing_rounded,
                  color: AppColors.primary,
                  bgColor: AppColors.accentMint,
                ),
                _buildStatCard(
                  title: _t('status_received'),
                  count: _receivedOrders,
                  icon: Icons.markunread_mailbox_rounded,
                  color: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFFEFF6FF),
                ),
                _buildStatCard(
                  title: _t('status_pending'),
                  count: _pendingOrders,
                  icon: Icons.hourglass_top_rounded,
                  color: const Color(0xFFF59E0B),
                  bgColor: const Color(0xFFFFFBEB),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDistributionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalCard({required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.85)],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$_totalOrders',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _t('status_distribution'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressBar(
            label: _t('status_delivered'),
            count: _deliveredOrders,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: _t('status_in_production'),
            count: _inProductionOrders,
            color: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: _t('status_received'),
            count: _receivedOrders,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 12),
          _buildProgressBar(
            label: _t('status_pending'),
            count: _pendingOrders,
            color: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required int count,
    required Color color,
  }) {
    final double percent = _totalOrders > 0 ? (count / _totalOrders) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '($count) ${(percent * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
