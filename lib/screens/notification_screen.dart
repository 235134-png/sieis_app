import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _notificationService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    setState(() {});
  }

  void _showNotificationDetail(AppNotification item) {
    _notificationService.markAsRead(item.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.priorityColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.description,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF374151),
                height: 1.4,
              ),
            ),
            if (item.actionRecommendation != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_rounded,
                          color: Color(0xFF0F766E),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Recommended Action',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F766E),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.actionRecommendation!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF1F2937),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(bottomContext),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text(
                'Close Notification',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allList = _notificationService.notifications;

    final filtered = allList.where((item) {
      if (_selectedFilter == 'Critical') {
        return item.priority == NotificationPriority.critical;
      } else if (_selectedFilter == 'Warnings') {
        return item.priority == NotificationPriority.warning;
      } else if (_selectedFilter == 'AI') {
        return item.category == NotificationCategory.aiPrediction;
      } else if (_selectedFilter == 'Actions') {
        return item.category == NotificationCategory.action ||
            item.actionRecommendation != null;
      }
      return true;
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF162033),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Alerts, AI forecasts, and recommended actions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF687386),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              if (_notificationService.unreadCount > 0)
                TextButton.icon(
                  onPressed: () => _notificationService.markAllAsRead(),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: const Text('Mark all read'),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Priority Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All'),
                _filterChip('Critical'),
                _filterChip('Warnings'),
                _filterChip('AI'),
                _filterChip('Actions'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (filtered.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: const Padding(
                padding: EdgeInsets.all(28),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 44, color: Color(0xFF9CA3AF)),
                      SizedBox(height: 12),
                      Text(
                        'No notifications found',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ...filtered.map((item) => _buildNotificationCard(item)),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: const Color(0xFFE0F2F1),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF4B5563),
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
        onSelected: (val) {
          if (val) {
            setState(() => _selectedFilter = label);
          }
        },
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isRead
              ? Colors.black.withValues(alpha: 0.06)
              : item.priorityColor.withValues(alpha: 0.4),
          width: item.isRead ? 1 : 1.5,
        ),
      ),
      color: item.isRead ? Colors.white : item.priorityColor.withValues(alpha: 0.03),
      child: InkWell(
        onTap: () => _showNotificationDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.priorityColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, color: item.priorityColor, size: 22),
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
                                  fontWeight: item.isRead
                                      ? FontWeight.w700
                                      : FontWeight.w900,
                                  fontSize: 15,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                            ),
                            if (!item.isRead) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF2563EB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              _formatTimestamp(item.timestamp),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.actionRecommendation != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showNotificationDetail(item),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text(
                        'View Details',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
