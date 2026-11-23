import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/device_pairing_flow_screen.dart';
import 'screens/login_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/device_service.dart';
import 'services/notification_service.dart';
import 'services/sensor_service.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase.initializeApp() note: $e');
  }
  runApp(const SieisApp());
}

class SieisApp extends StatefulWidget {
  const SieisApp({super.key});

  @override
  State<SieisApp> createState() => _SieisAppState();
}

class _SieisAppState extends State<SieisApp> {
  final AuthService _authService = AuthService();
  final DeviceService _deviceService = DeviceService();
  final SensorService _sensorService = SensorService();
  final ThemeService _themeService = ThemeService();
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _authService.addListener(_onStateChanged);
    _deviceService.addListener(_onStateChanged);
    _themeService.addListener(_onStateChanged);
    _sensorService.initializeFirebaseSensorStream();
  }

  @override
  void dispose() {
    _authService.removeListener(_onStateChanged);
    _deviceService.removeListener(_onStateChanged);
    _themeService.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lightColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );

    final darkColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIEIS',
      themeMode: _themeService.themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFFE0F2F1),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: const Color(0xFF111827),
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF1F2937),
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: const Color(0xFF0F766E),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ),
      home: _showSplash
          ? SplashScreen(
              onGetStarted: () {
                setState(() => _showSplash = false);
              },
            )
          : !_authService.isAuthenticated
              ? AuthFlowScreen(authService: _authService)
              : !_deviceService.isDevicePaired
                  ? DevicePairingFlowScreen(
                      onPairingComplete: () {
                        setState(() {});
                      },
                    )
                  : AppShell(authService: _authService),
    );
  }
}

class AuthFlowScreen extends StatefulWidget {
  const AuthFlowScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends State<AuthFlowScreen> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _showLogin
          ? LoginScreen(
              key: const ValueKey('login_screen'),
              authService: widget.authService,
              onNavigateToSignUp: () {
                widget.authService.clearError();
                setState(() => _showLogin = false);
              },
            )
          : SignUpScreen(
              key: const ValueKey('signup_screen'),
              authService: widget.authService,
              onNavigateToLogin: () {
                widget.authService.clearError();
                setState(() => _showLogin = true);
              },
            ),
    );
  }
}

enum RiskLevel { good, moderate, poor }

extension RiskLevelX on RiskLevel {
  int get severity {
    switch (this) {
      case RiskLevel.good:
        return 0;
      case RiskLevel.moderate:
        return 1;
      case RiskLevel.poor:
        return 2;
    }
  }

  String get label {
    switch (this) {
      case RiskLevel.good:
        return 'Healthy';
      case RiskLevel.moderate:
        return 'Moderate';
      case RiskLevel.poor:
        return 'Attention';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.good:
        return const Color(0xFF0F9F6E);
      case RiskLevel.moderate:
        return const Color(0xFFE09B22);
      case RiskLevel.poor:
        return const Color(0xFFD64545);
    }
  }

  Color get backgroundColor {
    switch (this) {
      case RiskLevel.good:
        return const Color(0xFFE6F7EF);
      case RiskLevel.moderate:
        return const Color(0xFFFFF3D6);
      case RiskLevel.poor:
        return const Color(0xFFFFE4E4);
    }
  }

  IconData get icon {
    switch (this) {
      case RiskLevel.good:
        return Icons.check_circle_rounded;
      case RiskLevel.moderate:
        return Icons.info_outline_rounded;
      case RiskLevel.poor:
        return Icons.warning_amber_rounded;
    }
  }
}

class MetricReading {
  MetricReading({
    required this.id,
    required this.name,
    required this.shortName,
    required this.unit,
    required this.value,
    required this.predicted,
    required this.min,
    required this.max,
    required this.icon,
    required this.color,
    required this.history,
    required this.assess,
    required this.recommendation,
  });

  final String id;
  final String name;
  final String shortName;
  final String unit;
  double value;
  double predicted;
  final double min;
  final double max;
  final IconData icon;
  final Color color;
  final List<double> history;
  final RiskLevel Function(double value) assess;
  final String recommendation;

  RiskLevel get currentRisk => assess(value);
  RiskLevel get predictedRisk => assess(predicted);

  double get normalized {
    final range = max - min;
    if (range <= 0) {
      return 0;
    }
    return ((value - min) / range).clamp(0.0, 1.0).toDouble();
  }

  String formatted(double input) {
    if (id == 'temp') {
      return input.toStringAsFixed(1);
    }
    return input.round().toString();
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final NotificationService _notificationService = NotificationService();
  final DeviceService _deviceService = DeviceService();
  final SensorService _sensorService = SensorService();

  late final List<MetricReading> _metrics;
  int _selectedIndex = 0;
  DateTime _lastSync = DateTime.now();

  @override
  void initState() {
    super.initState();
    _metrics = _seedMetrics();
    _notificationService.addListener(_onNotificationChanged);
    _sensorService.addListener(_onSensorDataReceived);
    _onSensorDataReceived();
  }

  @override
  void dispose() {
    _notificationService.removeListener(_onNotificationChanged);
    _sensorService.removeListener(_onSensorDataReceived);
    super.dispose();
  }

  void _onNotificationChanged() {
    setState(() {});
  }

  void _onSensorDataReceived() {
    final live = _sensorService.latestData;
    setState(() {
      for (final metric in _metrics) {
        if (metric.id == 'co2') metric.value = live.co2;
        if (metric.id == 'voc') metric.value = live.voc;
        if (metric.id == 'temp') metric.value = live.temp;
        if (metric.id == 'humidity') metric.value = live.humidity;
        if (metric.id == 'smoke') metric.value = live.smoke;
        metric.predicted =
            (metric.value * 1.05).clamp(metric.min, metric.max).toDouble();
        metric.history.add(metric.value);
        if (metric.history.length > 30) {
          metric.history.removeAt(0);
        }
      }
      _lastSync = live.lastUpdated;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        metrics: _metrics,
        lastSync: _lastSync,
        onRefresh: _refreshFromFirebase,
        authService: widget.authService,
        deviceService: _deviceService,
        sensorService: _sensorService,
        onOpenNotifications: () => setState(() => _selectedIndex = 3),
      ),
      ForecastScreen(metrics: _metrics),
      TrendsScreen(metrics: _metrics),
      const NotificationScreen(),
      SettingsScreen(authService: widget.authService),
    ];

    final unreadCount = _notificationService.unreadCount;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.auto_graph_rounded),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Forecasting',
          ),
          const NavigationDestination(
            icon: Icon(Icons.show_chart_rounded),
            selectedIcon: Icon(Icons.stacked_line_chart_rounded),
            label: 'Trends',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text('$unreadCount'),
              child: const Icon(Icons.notifications_active_rounded),
            ),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  List<MetricReading> _seedMetrics() {
    return [
      MetricReading(
        id: 'co2',
        name: 'Carbon Dioxide',
        shortName: 'CO2',
        unit: 'ppm',
        value: 1495,
        predicted: 1570,
        min: 400,
        max: 2000,
        icon: Icons.co2_rounded,
        color: const Color(0xFF0F766E),
        history: _history(740, 1500, 24),
        assess: (value) {
          if (value <= 800) return RiskLevel.good;
          if (value <= 1200) return RiskLevel.moderate;
          return RiskLevel.poor;
        },
        recommendation: 'Open windows or improve ventilation for 10 minutes.',
      ),
      MetricReading(
        id: 'voc',
        name: 'Volatile Organic Compounds',
        shortName: 'VOCs',
        unit: 'ppb',
        value: 166,
        predicted: 180,
        min: 0,
        max: 900,
        icon: Icons.air_rounded,
        color: const Color(0xFF7C3AED),
        history: _history(120, 320, 24),
        assess: (value) {
          if (value <= 250) return RiskLevel.good;
          if (value <= 500) return RiskLevel.moderate;
          return RiskLevel.poor;
        },
        recommendation:
            'Remove odor sources and avoid sprays or harsh cleaners.',
      ),
      MetricReading(
        id: 'temp',
        name: 'Temperature',
        shortName: 'Temp',
        unit: 'C',
        value: 32.0,
        predicted: 33.5,
        min: 14,
        max: 36,
        icon: Icons.thermostat_rounded,
        color: const Color(0xFFE05D2D),
        history: _history(22.0, 33.0, 24),
        assess: (value) {
          if (value >= 20 && value <= 26) return RiskLevel.good;
          if (value >= 18 && value <= 30) return RiskLevel.moderate;
          return RiskLevel.poor;
        },
        recommendation: 'Adjust cooling or reduce heat sources near the room.',
      ),
      MetricReading(
        id: 'humidity',
        name: 'Humidity',
        shortName: 'Humidity',
        unit: '%',
        value: 64,
        predicted: 68,
        min: 15,
        max: 90,
        icon: Icons.water_drop_rounded,
        color: const Color(0xFF2563EB),
        history: _history(42, 68, 24),
        assess: (value) {
          if (value >= 40 && value <= 60) return RiskLevel.good;
          if (value >= 30 && value <= 70) return RiskLevel.moderate;
          return RiskLevel.poor;
        },
        recommendation:
            'Use ventilation or dehumidification to bring humidity closer to 40-60%.',
      ),
      MetricReading(
        id: 'smoke',
        name: 'Smoke & Air Quality',
        shortName: 'Smoke',
        unit: 'ppm',
        value: 1712,
        predicted: 1800,
        min: 0,
        max: 2000,
        icon: Icons.cloud_outlined,
        color: const Color(0xFFDC2626),
        history: _history(500, 1800, 24),
        assess: (value) {
          if (value <= 20) return RiskLevel.good;
          if (value <= 50) return RiskLevel.moderate;
          return RiskLevel.poor;
        },
        recommendation:
            'Smoke particles or combustion detected. Inspect room area and ensure adequate ventilation.',
      ),
    ];
  }

  static List<double> _history(double low, double high, int count) {
    final random = Random((low * high).round());
    var cursor = low + ((high - low) * 0.45);
    return List<double>.generate(count, (index) {
      final seasonal = sin(index / 4) * ((high - low) * 0.17);
      final noise = (random.nextDouble() - 0.5) * ((high - low) * 0.2);
      cursor =
          (cursor + seasonal * 0.08 + noise * 0.15).clamp(low, high).toDouble();
      return cursor;
    });
  }

  void _refreshFromFirebase() {
    final activeId = _deviceService.activeDevice?.id ?? 'esp32_01';
    _sensorService.initializeFirebaseSensorStream(deviceId: activeId);
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.metrics,
    required this.lastSync,
    required this.onRefresh,
    required this.authService,
    required this.deviceService,
    required this.sensorService,
    required this.onOpenNotifications,
  });

  final List<MetricReading> metrics;
  final DateTime lastSync;
  final VoidCallback onRefresh;
  final AuthService authService;
  final DeviceService deviceService;
  final SensorService sensorService;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final risk = overallRisk(metrics);
    final worstMetric = mostUrgentMetric(metrics);
    final user = authService.currentUser;
    final activeDevice = deviceService.activeDevice;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            PageHeader(
              title: 'Dashboard',
              subtitle: activeDevice != null
                  ? '${activeDevice.room} • ${activeDevice.id}'
                  : 'Computer Lab A • esp32_01',
              user: user,
              onOpenNotifications: onOpenNotifications,
              onSignOut: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out of SIEIS?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD64545),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(dialogCtx, true),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await authService.logout();
                }
              },
              trailing: IconButton.filledTonal(
                tooltip: 'Refresh readings',
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ),
            const SizedBox(height: 14),
            AirStatusPanel(
              risk: risk,
              metric: worstMetric,
              lastSync: lastSync,
              isFirebaseConnected: sensorService.isFirebaseConnected,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF0F766E)),
                const SizedBox(width: 8),
                Text(
                  'Monitored Air Parameters',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF162033),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            MetricGrid(metrics: metrics),
            const SizedBox(height: 14),
            ForecastBanner(metric: worstMetric),
            const SizedBox(height: 14),
            RecommendationCard(metric: worstMetric),
          ],
        ),
      ),
    );
  }
}

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key, required this.metrics});

  final List<MetricReading> metrics;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          const PageHeader(title: 'Trends', subtitle: 'Historical sensor analysis'),
          const SizedBox(height: 14),
          const TimeRangeSelector(),
          const SizedBox(height: 14),
          ...metrics.map(
            (metric) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TrendCard(metric: metric),
            ),
          ),
        ],
      ),
    );
  }
}

class ForecastScreen extends StatelessWidget {
  const ForecastScreen({super.key, required this.metrics});

  final List<MetricReading> metrics;

  @override
  Widget build(BuildContext context) {
    final metric = mostUrgentMetric(metrics);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        children: [
          const PageHeader(
            title: 'AI Forecast',
            subtitle: 'Next indoor condition estimate',
          ),
          const SizedBox(height: 14),
          PredictionSummary(metric: metric),
          const SizedBox(height: 14),
          ...metrics.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ForecastTimeline(metric: item),
            ),
          ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.user,
    this.onSignOut,
    this.onOpenNotifications,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final UserSession? user;
  final VoidCallback? onSignOut;
  final VoidCallback? onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationService();
    final unread = notificationService.unreadCount;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF162033),
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF687386),
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
        if (onOpenNotifications != null) ...[
          IconButton(
            tooltip: 'Notifications',
            onPressed: onOpenNotifications,
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_none_rounded, size: 24),
            ),
          ),
          const SizedBox(width: 4),
        ],
        if (user != null) ...[
          PopupMenuButton<String>(
            tooltip: 'Account Options',
            onSelected: (value) {
              if (value == 'logout' && onSignOut != null) {
                onSignOut!();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          user!.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (user!.provider == AuthProvider.google)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F0FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A73E8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      user!.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD64545),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFFD64545),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF0F766E),
              child: Text(
                user!.name.isNotEmpty ? user!.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AirStatusPanel extends StatelessWidget {
  const AirStatusPanel({
    super.key,
    required this.risk,
    required this.metric,
    required this.lastSync,
    this.isFirebaseConnected = false,
  });

  final RiskLevel risk;
  final MetricReading metric;
  final DateTime lastSync;
  final bool isFirebaseConnected;

  @override
  Widget build(BuildContext context) {
    final titleText = risk == RiskLevel.good
        ? 'Indoor Air Quality is Fresh & Healthy'
        : risk == RiskLevel.moderate
            ? '${metric.shortName} Needs Moderate Attention'
            : '${metric.shortName} Level High — Action Required';

    final gradientColors = risk == RiskLevel.good
        ? [const Color(0xFF0F766E), const Color(0xFF047857)]
        : risk == RiskLevel.moderate
            ? [const Color(0xFFB45309), const Color(0xFFD97706)]
            : [const Color(0xFFB91C1C), const Color(0xFFDC2626)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      risk.icon,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      risk.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors_rounded,
                      size: 14,
                      color: isFirebaseConnected
                          ? const Color(0xFF9EEAD9)
                          : const Color(0xFFFBBF24),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isFirebaseConnected
                          ? 'Firebase Live Sync'
                          : 'Sensor Stream',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            titleText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Currently at ${metric.formatted(metric.value)} ${metric.unit} — predicted to reach ${metric.formatted(metric.predicted)} ${metric.unit} in the next hour.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 14,
                color: Colors.white70,
              ),
              const SizedBox(width: 6),
              Text(
                'Updated ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MetricGrid extends StatelessWidget {
  const MetricGrid({super.key, required this.metrics});

  final List<MetricReading> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 560;
        final crossAxisCount = isWide ? 4 : 2;
        return GridView.builder(
          itemCount: metrics.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: isWide ? 0.98 : 0.92,
          ),
          itemBuilder: (context, index) => MetricCard(metric: metrics[index]),
        );
      },
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.metric});

  final MetricReading metric;

  void _showMetricDetailModal(BuildContext context, MetricReading metric) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ListenableBuilder(
        listenable: SensorService(),
        builder: (context, _) {
          final live = SensorService().latestData;
          if (metric.id == 'co2') metric.value = live.co2;
          if (metric.id == 'voc') metric.value = live.voc;
          if (metric.id == 'temp') metric.value = live.temp;
          if (metric.id == 'humidity') metric.value = live.humidity;
          if (metric.id == 'smoke') metric.value = live.smoke;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 20),
            Row(
              children: [
                IconBox(icon: metric.icon, color: metric.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Parameter: ${metric.shortName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                RiskPill(risk: metric.currentRisk, compact: false),
              ],
            ),
            const SizedBox(height: 24),

            // Live Reading Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: metric.currentRisk.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: metric.currentRisk.color.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Reading',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          text: metric.formatted(metric.value),
                          style: TextStyle(
                            color: metric.currentRisk.color,
                            fontWeight: FontWeight.w900,
                            fontSize: 34,
                          ),
                          children: [
                            TextSpan(
                              text: ' ${metric.unit}',
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '1-Hour Forecast',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${metric.formatted(metric.predicted)} ${metric.unit}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Safe Range Progress Indicator
            const Text(
              'Comfort Range Scale',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: metric.normalized,
                minHeight: 8,
                backgroundColor: metric.color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation<Color>(metric.currentRisk.color),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Min ${metric.formatted(metric.min)} ${metric.unit}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                Text(
                  'Max ${metric.formatted(metric.max)} ${metric.unit}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 24-Hour Sparkline Chart
            const Text(
              '24-Hour History Trend',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: Sparkline(values: metric.history, color: metric.color),
            ),

            const SizedBox(height: 20),

            // Action Tip
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: Color(0xFF0F766E),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metric.recommendation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Close Details',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );
    },
  ),
);
}

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: metric.currentRisk.color.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: InkWell(
        onTap: () => _showMetricDetailModal(context, metric),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconBox(icon: metric.icon, color: metric.color),
                  const Spacer(),
                  RiskPill(risk: metric.currentRisk, compact: true),
                ],
              ),
              const Spacer(),
              Text(
                metric.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: metric.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Show Details',
                      style: TextStyle(
                        color: metric.color,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 9,
                      color: metric.color,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

class RiskDot extends StatelessWidget {
  const RiskDot({super.key, required this.risk});

  final RiskLevel risk;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: risk.label,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(color: risk.color, shape: BoxShape.circle),
      ),
    );
  }
}

class RiskPill extends StatelessWidget {
  const RiskPill({super.key, required this.risk, this.compact = true});

  final RiskLevel risk;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 7,
      ),
      decoration: BoxDecoration(
        color: risk.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(risk.icon, size: compact ? 12 : 16, color: risk.color),
          const SizedBox(width: 4),
          Text(
            risk.label,
            style: TextStyle(
              color: risk.color,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SparklinePainter(values: values, color: color),
      size: Size.infinite,
    );
  }
}

class SparklinePainter extends CustomPainter {
  const SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) {
      return;
    }
    final minValue = values.reduce(min);
    final maxValue = values.reduce(max);
    final range = max(maxValue - minValue, 0.001);
    final path = Path();

    for (var index = 0; index < values.length; index++) {
      final x = index / (values.length - 1) * size.width;
      final y =
          size.height - ((values[index] - minValue) / range * size.height);
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.02)
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return true;
  }
}

class ForecastBanner extends StatelessWidget {
  const ForecastBanner({super.key, required this.metric});

  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            IconBox(
              icon: Icons.insights_rounded,
              color: metric.predictedRisk.color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '1-Hour AI Prediction',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${metric.shortName} may reach ${metric.formatted(metric.predicted)} ${metric.unit} in the next hour.',
                    style: const TextStyle(
                      color: Color(0xFF687386),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            RiskPill(risk: metric.predictedRisk),
          ],
        ),
      ),
    );
  }
}

class RecommendationCard extends StatelessWidget {
  const RecommendationCard({super.key, required this.metric});

  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox(
                  icon: Icons.tips_and_updates_rounded,
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recommended Action',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              metric.recommendation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeRangeSelector extends StatefulWidget {
  const TimeRangeSelector({super.key});

  @override
  State<TimeRangeSelector> createState() => _TimeRangeSelectorState();
}

class _TimeRangeSelectorState extends State<TimeRangeSelector> {
  int selected = 1;
  final labels = const ['1H', '24H', '7D'];

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (var i = 0; i < labels.length; i++)
          ButtonSegment<int>(
            value: i,
            label: Text(labels[i]),
            icon: Icon(
              i == 0
                  ? Icons.schedule_rounded
                  : i == 1
                      ? Icons.today_rounded
                      : Icons.date_range_rounded,
            ),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (value) => setState(() => selected = value.first),
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({super.key, required this.metric});

  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    final high = metric.history.reduce(max);
    final low = metric.history.reduce(min);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox(icon: metric.icon, color: metric.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        metric.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'Low ${metric.formatted(low)} ${metric.unit}  High ${metric.formatted(high)} ${metric.unit}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                RiskPill(risk: metric.currentRisk),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 116,
              child: Sparkline(values: metric.history, color: metric.color),
            ),
          ],
        ),
      ),
    );
  }
}

class PredictionSummary extends StatelessWidget {
  const PredictionSummary({super.key, required this.metric});

  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: metric.predictedRisk.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: metric.predictedRisk.color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            metric.predictedRisk.icon,
            color: metric.predictedRisk.color,
            size: 34,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${metric.shortName} is the main forecast risk',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF172033),
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Model confidence 86%. Next-hour estimate is ${metric.formatted(metric.predicted)} ${metric.unit}.',
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ForecastTimeline extends StatelessWidget {
  const ForecastTimeline({super.key, required this.metric});

  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ForecastStep(label: 'Now', value: metric.value, risk: metric.currentRisk),
      ForecastStep(
        label: '+1h',
        value: metric.predicted,
        risk: metric.predictedRisk,
      ),
      ForecastStep(
        label: '+2h',
        value:
            (metric.predicted * 1.04).clamp(metric.min, metric.max).toDouble(),
        risk: metric.assess(
          (metric.predicted * 1.04).clamp(metric.min, metric.max).toDouble(),
        ),
      ),
      ForecastStep(
        label: '+4h',
        value:
            (metric.predicted * 1.07).clamp(metric.min, metric.max).toDouble(),
        risk: metric.assess(
          (metric.predicted * 1.07).clamp(metric.min, metric.max).toDouble(),
        ),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBox(icon: metric.icon, color: metric.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    metric.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Expanded(
                    child: ForecastStepTile(step: steps[i], metric: metric),
                  ),
                  if (i != steps.length - 1)
                    Container(
                      width: 18,
                      height: 2,
                      color: const Color(0xFFE5E7EB),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ForecastStep {
  const ForecastStep({
    required this.label,
    required this.value,
    required this.risk,
  });

  final String label;
  final double value;
  final RiskLevel risk;
}

class ForecastStepTile extends StatelessWidget {
  const ForecastStepTile({super.key, required this.step, required this.metric});

  final ForecastStep step;
  final MetricReading metric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: step.risk.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Icon(step.risk.icon, color: step.risk.color, size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          step.label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${metric.formatted(step.value)} ${metric.unit}',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class SystemFlowCard extends StatelessWidget {
  const SystemFlowCard({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = const [
      (Icons.sensors_rounded, 'IoT sensors'),
      (Icons.cloud_queue_rounded, 'Cloud storage'),
      (Icons.psychology_rounded, 'AI forecast'),
      (Icons.phone_android_rounded, 'Mobile guidance'),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SIEIS Architecture',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2F1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            steps[i].$1,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          steps[i].$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != steps.length - 1)
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF9CA3AF),
                    ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

RiskLevel overallRisk(List<MetricReading> metrics) {
  return metrics
      .map(
        (metric) => metric.predictedRisk.severity > metric.currentRisk.severity
            ? metric.predictedRisk
            : metric.currentRisk,
      )
      .reduce((a, b) => a.severity >= b.severity ? a : b);
}

MetricReading mostUrgentMetric(List<MetricReading> metrics) {
  final sorted = [...metrics]..sort((a, b) {
      final bRisk = max(b.currentRisk.severity, b.predictedRisk.severity);
      final aRisk = max(a.currentRisk.severity, a.predictedRisk.severity);
      return bRisk.compareTo(aRisk);
    });
  return sorted.first;
}
