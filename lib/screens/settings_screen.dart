import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/notification_service.dart';
import '../services/theme_service.dart';
import 'edit_profile_screen.dart';
import 'manage_device_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DeviceService _deviceService = DeviceService();
  final NotificationService _notificationService = NotificationService();
  final ThemeService _themeService = ThemeService();

  // Notification Preferences
  bool _enableNotifications = true;
  bool _criticalAlerts = true;
  bool _predictionAlerts = true;
  bool _actionRecommendations = true;
  bool _soundVibration = true;

  // Threshold Preferences
  double _co2Threshold = 800;
  double _tvocThreshold = 250;

  // Appearance
  String _themeMode = 'Light';

  @override
  void initState() {
    super.initState();
    _deviceService.addListener(_onDeviceChanged);
    _themeService.addListener(_onThemeChanged);
    _enableNotifications = _notificationService.enableMaster;
    _criticalAlerts = _notificationService.enableCritical;
    _predictionAlerts = _notificationService.enableAiWarnings;
    _soundVibration = _notificationService.enableSoundVibration;
    _themeMode = _themeService.themeModeName;
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceChanged);
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onDeviceChanged() {
    setState(() {});
  }

  void _onThemeChanged() {
    setState(() {
      _themeMode = _themeService.themeModeName;
    });
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & FAQ'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How does SIEIS work?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'SIEIS connects to your IoT ESP32 sensors to monitor CO₂, TVOC, temperature, humidity, and smoke, giving real-time data and AI predictions.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              SizedBox(height: 14),
              Text(
                'How do I pair a new device?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Go to Settings → Manage Device → Pair Another Device via Camera QR and scan the QR code on your ESP32.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.authService.currentUser;
    final activeDevice = _deviceService.activeDevice;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF162033),
                ),
          ),
          const SizedBox(height: 2),
          Text(
            'App preferences, device controls, and thresholds',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF687386),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 18),

          // 1. Account Group (Edit Profile)
          _buildSectionHeader('Account (Edit Profile)', Icons.person_outline_rounded),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF0F766E),
                        child: Text(
                          user?.name.isNotEmpty == true
                              ? user!.name[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.name ?? 'User',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (user?.provider == AuthProvider.google)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
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
                              user?.email ?? '',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF687386),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Sign Out',
                        icon: const Icon(Icons.logout_rounded, color: Color(0xFFD64545)),
                        onPressed: () => widget.authService.logout(),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.manage_accounts_outlined, color: Color(0xFF0F766E)),
                    title: const Text('Edit Profile Page', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Update name, email, phone number & bio'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(authService: widget.authService),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 2. Device Group (Manage Device)
          _buildSectionHeader('Manage Device (View or Alter Paired Device)', Icons.sensors_rounded),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: activeDevice != null ? const Color(0xFF0F9F6E) : const Color(0xFF9CA3AF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activeDevice?.name ?? 'No Connected Device',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              activeDevice != null
                                  ? 'ID: ${activeDevice.id} • Room: ${activeDevice.room}'
                                  : 'Tap Manage Device to scan QR and pair',
                              style: const TextStyle(
                                color: Color(0xFF687386),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.developer_board_rounded, color: Color(0xFF0F766E)),
                    title: const Text('Manage Device Page', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Specs, room assignment, QR pair & unpair'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ManageDeviceScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 3. Notification Control (Toggle Alerts On/Off)
          _buildSectionHeader('Notification Control (Toggle Alerts On/Off)', Icons.notifications_none_rounded),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _enableNotifications,
                  onChanged: (val) {
                    setState(() => _enableNotifications = val);
                    _notificationService.updateNotificationControls(
                      master: val,
                      critical: _criticalAlerts,
                      aiWarnings: _predictionAlerts,
                      soundVibration: _soundVibration,
                    );
                  },
                  title: const Text('Master Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
                SwitchListTile(
                  value: _criticalAlerts,
                  onChanged: _enableNotifications
                      ? (val) {
                          setState(() => _criticalAlerts = val);
                          _notificationService.updateNotificationControls(
                            master: _enableNotifications,
                            critical: val,
                            aiWarnings: _predictionAlerts,
                            soundVibration: _soundVibration,
                          );
                        }
                      : null,
                  title: const Text('Critical Threshold Alerts'),
                  secondary: const Icon(Icons.error_outline_rounded),
                ),
                SwitchListTile(
                  value: _predictionAlerts,
                  onChanged: _enableNotifications
                      ? (val) {
                          setState(() => _predictionAlerts = val);
                          _notificationService.updateNotificationControls(
                            master: _enableNotifications,
                            critical: _criticalAlerts,
                            aiWarnings: val,
                            soundVibration: _soundVibration,
                          );
                        }
                      : null,
                  title: const Text('AI Forecast Warnings'),
                  secondary: const Icon(Icons.insights_rounded),
                ),
                SwitchListTile(
                  value: _actionRecommendations,
                  onChanged: _enableNotifications
                      ? (val) => setState(() => _actionRecommendations = val)
                      : null,
                  title: const Text('Action Recommendations'),
                  secondary: const Icon(Icons.tips_and_updates_outlined),
                ),
                SwitchListTile(
                  value: _soundVibration,
                  onChanged: _enableNotifications
                      ? (val) {
                          setState(() => _soundVibration = val);
                          _notificationService.updateNotificationControls(
                            master: _enableNotifications,
                            critical: _criticalAlerts,
                            aiWarnings: _predictionAlerts,
                            soundVibration: val,
                          );
                        }
                      : null,
                  title: const Text('Sound & Vibration'),
                  secondary: const Icon(Icons.volume_up_outlined),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // 4. Threshold Preferences
          _buildSectionHeader('Environmental Thresholds', Icons.tune_rounded),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'CO₂ Alert Threshold',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_co2Threshold.round()} ppm (Target: 800)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _co2Threshold,
                    min: 600,
                    max: 1500,
                    divisions: 18,
                    activeColor: const Color(0xFF0F766E),
                    onChanged: (val) => setState(() => _co2Threshold = val),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'TVOC Alert Threshold',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_tvocThreshold.round()} ppb (Target: 250)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F766E),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _tvocThreshold,
                    min: 150,
                    max: 600,
                    divisions: 18,
                    activeColor: const Color(0xFF0F766E),
                    onChanged: (val) => setState(() => _tvocThreshold = val),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 5. Appearance (Dark Mode Switch)
          _buildSectionHeader('Appearance & Theme', Icons.palette_outlined),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('App Theme Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Light', label: Text('Light'), icon: Icon(Icons.wb_sunny_outlined)),
                        ButtonSegment(value: 'Dark', label: Text('Dark'), icon: Icon(Icons.nightlight_outlined)),
                        ButtonSegment(value: 'System', label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                      ],
                      selected: {_themeMode},
                      onSelectionChanged: (val) {
                        setState(() => _themeMode = val.first);
                        _themeService.setThemeMode(val.first);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // 6. About & Support
          _buildSectionHeader('About & Support', Icons.info_outline_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded),
                  title: const Text('Help & FAQ'),
                  onTap: _showHelpDialog,
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SIEIS protects your indoor environmental telemetry data.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const ListTile(
                  leading: Icon(Icons.verified_outlined),
                  title: Text('SIEIS Version'),
                  subtitle: Text('1.0.0 (Build 100)'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F766E)),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF162033),
            ),
          ),
        ],
      ),
    );
  }
}
