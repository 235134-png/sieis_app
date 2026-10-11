import 'package:flutter/material.dart';

enum NotificationPriority { critical, warning, info, recommendation }

enum NotificationCategory { environmental, system, aiPrediction, action }

class AppNotification {
  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  bool isRead;
  final NotificationPriority priority;
  final NotificationCategory category;
  final String? actionRecommendation;

  AppNotification({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.isRead = false,
    required this.priority,
    required this.category,
    this.actionRecommendation,
  });

  Color get priorityColor {
    switch (priority) {
      case NotificationPriority.critical:
        return const Color(0xFFD64545);
      case NotificationPriority.warning:
        return const Color(0xFFE09B22);
      case NotificationPriority.recommendation:
        return const Color(0xFF0F766E);
      case NotificationPriority.info:
        return const Color(0xFF2563EB);
    }
  }

  IconData get icon {
    switch (category) {
      case NotificationCategory.environmental:
        return Icons.air_rounded;
      case NotificationCategory.system:
        return Icons.sensors_rounded;
      case NotificationCategory.aiPrediction:
        return Icons.insights_rounded;
      case NotificationCategory.action:
        return Icons.tips_and_updates_rounded;
    }
  }
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal() {
    _notifications = [
      AppNotification(
        id: 'n1',
        title: 'High CO₂ Detected',
        description: 'Carbon dioxide level crossed 1000 ppm (1080 ppm). Ventilation recommended.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isRead: false,
        priority: NotificationPriority.critical,
        category: NotificationCategory.environmental,
        actionRecommendation: 'Open room windows or turn on exhaust fans for 10 minutes to reduce CO₂ accumulation.',
      ),
      AppNotification(
        id: 'n2',
        title: 'Air Quality Expected to Decline',
        description: 'AI model predicts TVOC will rise from 310 ppb to 470 ppb in the next hour.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        priority: NotificationPriority.warning,
        category: NotificationCategory.aiPrediction,
        actionRecommendation: 'Check for open solvent containers or cleaning sprays in the lab.',
      ),
      AppNotification(
        id: 'n3',
        title: 'ESP32 Device Sync Completed',
        description: 'ESP32 Node 1 re-established stable Wi-Fi connection and synced 24h history.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
        priority: NotificationPriority.info,
        category: NotificationCategory.system,
      ),
      AppNotification(
        id: 'n4',
        title: 'Temperature Above Comfort Target',
        description: 'Indoor temperature measured at 28.0 °C (Target: 20-26 °C).',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isRead: true,
        priority: NotificationPriority.recommendation,
        category: NotificationCategory.action,
        actionRecommendation: 'Lower AC thermostat or reduce heat-generating equipment nearby.',
      ),
    ];
  }

  late List<AppNotification> _notifications;

  bool enableMaster = true;
  bool enableCritical = true;
  bool enableAiWarnings = true;
  bool enableSoundVibration = true;

  void updateNotificationControls({
    required bool master,
    required bool critical,
    required bool aiWarnings,
    required bool soundVibration,
  }) {
    enableMaster = master;
    enableCritical = critical;
    enableAiWarnings = aiWarnings;
    enableSoundVibration = soundVibration;
    notifyListeners();
  }

  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = true;
      notifyListeners();
    }
  }

  void markAllAsRead() {
    for (final n in _notifications) {
      n.isRead = true;
    }
    notifyListeners();
  }

  void deleteNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void toggleReadState(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index].isRead = !_notifications[index].isRead;
      notifyListeners();
    }
  }
}
