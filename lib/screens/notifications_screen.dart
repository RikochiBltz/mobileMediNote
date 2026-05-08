import 'package:flutter/material.dart';

import '../services/notification_service.dart';
import '../services/theme_provider.dart';
import '../theme/app_design.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _generateReminder() async {
    try {
      await _service.generateMine();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    await _service.markAllRead();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeInheritedWidget.of(context)?.isDarkMode ?? false;
    final bg = isDark ? AppDesign.darkBackground : Colors.white;
    final cardColor = AppDesign.surface(isDark);
    final textColor = AppDesign.textPrimary(isDark);
    final secondaryColor = AppDesign.textSecondary(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : AppDesign.green,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: cardColor,
        elevation: 1,
        actions: [
          IconButton(
            tooltip: 'Create a reminder',
            icon: const Icon(Icons.auto_awesome),
            color: AppDesign.green,
            onPressed: _generateReminder,
          ),
          IconButton(
            tooltip: 'Mark all read',
            icon: const Icon(Icons.done_all),
            color: AppDesign.green,
            onPressed: _items.any((item) => !item.read) ? _markAllRead : null,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppDesign.pageGradient(isDark),
          ),
        ),
        child: RefreshIndicator(
          color: AppDesign.green,
          onRefresh: _load,
          child: _body(cardColor, textColor, secondaryColor),
        ),
      ),
    );
  }

  Widget _body(Color cardColor, Color textColor, Color secondaryColor) {
    if (_loading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (_, __) => _skeleton(cardColor),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: 5,
      );
    }

    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _emptyState(
            icon: Icons.error_outline,
            title: 'Could not load notifications',
            subtitle: _error!,
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _emptyState(
            icon: Icons.notifications_none,
            title: 'No notifications yet',
            subtitle:
                'MediNote will remind you when there is a useful action to take.',
            textColor: textColor,
            secondaryColor: secondaryColor,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, index) => _notificationTile(
        _items[index],
        cardColor: cardColor,
        textColor: textColor,
        secondaryColor: secondaryColor,
      ),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: _items.length,
    );
  }

  Widget _notificationTile(
    AppNotification item, {
    required Color cardColor,
    required Color textColor,
    required Color secondaryColor,
  }) {
    final color = _priorityColor(item.priority);
    final isDark = ThemeInheritedWidget.of(context)?.isDarkMode ?? false;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: item.read
          ? null
          : () async {
              await _service.markRead(item.id);
              await _load();
            },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: item.read ? AppDesign.cardBorder(isDark) : color.withOpacity(0.34),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(item.read ? 0.04 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_typeIcon(item.type), color: color),
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
                          item.title,
                          style: TextStyle(
                            color: textColor,
                            fontWeight:
                                item.read ? FontWeight.w700 : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!item.read)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.body,
                    style: TextStyle(
                      color: secondaryColor,
                      height: 1.35,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(item.createdAt),
                    style: TextStyle(
                      color: secondaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color secondaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppDesign.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppDesign.green, size: 46),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryColor, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _skeleton(Color cardColor) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFE74C3C);
      case 'LOW':
        return const Color(0xFF2980B9);
      default:
        return AppDesign.green;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'COME_BACK':
        return Icons.login;
      case 'CHAT_VALUE':
      case 'STAFF_INSIGHT':
      case 'DELEGATE_ROUTE':
        return Icons.chat_bubble_outline;
      case 'REPORT_VALUE':
        return Icons.fact_check_outlined;
      case 'SCORE_COACH':
      case 'ADMIN_REVIEW':
        return Icons.workspace_premium_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
