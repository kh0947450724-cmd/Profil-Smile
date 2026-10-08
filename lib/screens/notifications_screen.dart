import 'package:flutter/material.dart';

import '../core/localization/app_localizations.dart';
import '../../models/notification_model.dart';
import '../core/services/notification_service.dart';
import '../core/theme/app_theme.dart';
import 'order_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  List<AppNotification> _notifications = [];

  AppLocalizations? get _loc => AppLocalizations.of(context);
  String _t(String key) => _loc?.translate(key) ?? key;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await NotificationService.loadNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════
  // فتح الإشعار والانتقال للطلب المرتبط
  // ═══════════════════════════════════════════════
  Future<void> _handleTap(AppNotification n) async {
    if (!n.isRead) {
      await NotificationService.markAsRead(n.id);
      setState(() {
        final idx = _notifications.indexWhere((e) => e.id == n.id);
        if (idx != -1) _notifications[idx].isRead = true;
      });
    }

    if (n.orderId != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsScreen(orderId: n.orderId!),
        ),
      );
    }
  }

  Future<void> _deleteOne(AppNotification n) async {
    await NotificationService.deleteNotification(n.id);
    setState(() => _notifications.removeWhere((e) => e.id == n.id));
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(_t('clear_all_notifications')),
        content: Text(_t('confirm_clear_all_notifications')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              _t('clear_all'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await NotificationService.clearAll();
      setState(() => _notifications = []);
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationService.markAllAsRead();
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return _t('just_now');
    if (diff.inMinutes < 60) {
      return _loc?.translateWithArgs('minutes_ago', {
            'count': '${diff.inMinutes}',
          }) ??
          '${diff.inMinutes}${_t('minutes_ago_short')}';
    }
    if (diff.inHours < 24) {
      return _loc?.translateWithArgs('hours_ago', {
            'count': '${diff.inHours}',
          }) ??
          '${diff.inHours}${_t('hours_ago_short')}';
    }
    if (diff.inDays < 7) {
      return _loc?.translateWithArgs('days_ago', {'count': '${diff.inDays}'}) ??
          '${diff.inDays}${_t('days_ago_short')}';
    }
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'new_order':
      case 'order_created':
        return Icons.add_circle_rounded;
      case 'order_updated':
      case 'status_updated':
        return Icons.update_rounded;
      case 'repeat_stage':
      case 'redo_requested':
      case 'needs_redo':
        return Icons.replay_rounded;
      case 'order_completed':
        return Icons.task_alt_rounded;
      case 'stage_approved':
        return Icons.check_circle_rounded;
      case 'order_cancelled':
        return Icons.cancel_rounded;
      case 'delivered':
        return Icons.local_shipping_rounded;
      case 'invoiced':
        return Icons.receipt_long_rounded;
      case 'message':
        return Icons.chat_bubble_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'new_order':
      case 'order_created':
        return const Color(0xFF10B981);
      case 'order_updated':
      case 'status_updated':
        return const Color(0xFF3B82F6);
      case 'repeat_stage':
      case 'redo_requested':
      case 'needs_redo':
        return const Color(0xFF8B5CF6);
      case 'order_completed':
      case 'stage_approved':
        return const Color(0xFF06B6D4);
      case 'order_cancelled':
        return const Color(0xFFEF4444);
      case 'invoiced':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Row(
          children: [
            Text(
              _t('notifications_title'),
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              tooltip: _t('mark_all_read'),
              icon: const Icon(Icons.done_all_rounded),
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
            ),
            IconButton(
              tooltip: _t('clear_all'),
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final n = _notifications[index];
                  return _buildNotificationTile(n);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationTile(AppNotification n) {
    final iconColor = _getColor(n.type);
    final icon = _getIcon(n.type);

    // ✅ استخدام النص المباشر (بلغة المستخدم القادم من السيرفر)
    final displayTitle = n.title.isEmpty ? _t('new_notification') : n.title;
    final displayBody = n.body;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: AlignmentDirectional.centerEnd,
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => _deleteOne(n),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : AppColors.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead
                ? Colors.grey.shade200
                : AppColors.primary.withOpacity(0.25),
            width: n.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _handleTap(n),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayTitle,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: n.isRead
                                      ? FontWeight.w600
                                      : FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!n.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayBody,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textLight,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTime(n.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textLight,
                              ),
                            ),
                            if (n.orderId != null) ...[
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${n.orderId}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _t('no_notifications_yet'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _t('no_notifications_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }
}
