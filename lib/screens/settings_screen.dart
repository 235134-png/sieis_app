import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/device_service.dart';
import '../services/notification_service.dart';
import 'device_pairing_flow_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DeviceService _deviceService = DeviceService();
  final NotificationService _notificationService = NotificationService();

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
    _enableNotifications = _notificationService.enableMaster;
    _criticalAlerts = _notificationService.enableCritical;
    _predictionAlerts = _notificationService.enableAiWarnings;
    _soundVibration = _notificationService.enableSoundVibration;
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void _onDeviceChanged() {
    setState(() {});
  }

  void _editProfileDialog() {
    final user = widget.authService.currentUser;
    final nameController = TextEditingController(text: user?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update account data:', style: TextStyle(fontSize: 13, color: Color(0xFF687386))),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              enabled: false,
              controller: TextEditingController(text: user?.email ?? ''),
              decoration: InputDecoration(
                labelText: 'Email Address (Account ID)',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                await widget.authService.updateProfileName(newName);
              }
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile updated successfully'),
                  backgroundColor: Color(0xFF0F9F6E),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  void _renameDeviceDialog() {
    final active = _deviceService.activeDevice;
    if (active == null) return;
    final controller = TextEditingController(text: active.name);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Device Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                _deviceService.renameDevice(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changeRoomDialog() {
    final active = _deviceService.activeDevice;
    if (active == null) return;
    final controller = TextEditingController(text: active.room);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Device Room'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Room / Location Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRoom = controller.text.trim();
              if (newRoom.isNotEmpty) {
                _deviceService.updateDeviceRoom(newRoom);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _unpairDeviceConfirm() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpair Device'),
        content: const Text(
          'Are you sure you want to disconnect and unpair this ESP32 device? You will need to pair a device again to view sensor data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              _deviceService.unpairDevice();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device unpaired successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
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
                'SIEIS connects to your IoT ESP32 sensors to monitor CO₂, TVOC, temperature, and humidity, giving real-time data and AI predictions.',
                style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
              ),
              SizedBox(height: 14),
              Text(
                'How do I pair a new device?',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4),
              Text(
                'Go to Settings → Device → Add / Connect Another Device and scan the QR code on your ESP32.',
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
                    title: const Text('Edit Profile (Update Account Data)', style: TextStyle(fontWeight: FontWeight.w700)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _editProfileDialog,
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
                  if (activeDevice != null) ...[
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Color(0xFF0F9F6E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeDevice.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                'ID: ${activeDevice.id} • Room: ${activeDevice.room}',
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
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Rename Device'),
                      onTap: _renameDeviceDialog,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.meeting_room_outlined),
                      title: const Text('Change Room Location'),
                      onTap: _changeRoomDialog,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0F766E)),
                      title: const Text('Scan QR Code to Add New Device', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0F766E))),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicePairingFlowScreen(
                              allowSkip: true,
                              onPairingComplete: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.link_off_rounded, color: Color(0xFFD64545)),
                      title: const Text(
                        'Unpair Current Device',
                        style: TextStyle(color: Color(0xFFD64545), fontWeight: FontWeight.w700),
                      ),
                      onTap: _unpairDeviceConfirm,
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No device currently connected.',
                        style: TextStyle(color: Color(0xFF687386)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DevicePairingFlowScreen(
                              allowSkip: true,
                              onPairingComplete: () {
                                Navigator.pop(context);
                              },
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Connect ESP32 Device via QR'),
                    ),
                  ],
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

          // 5. Appearance
          _buildSectionHeader('Appearance', Icons.palette_outlined),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Light', label: Text('Light'), icon: Icon(Icons.wb_sunny_outlined)),
                  ButtonSegment(value: 'Dark', label: Text('Dark'), icon: Icon(Icons.nightlight_outlined)),
                  ButtonSegment(value: 'System', label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                ],
                selected: {_themeMode},
                onSelectionChanged: (val) {
                  setState(() => _themeMode = val.first);
                },
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
