import 'package:flutter/material.dart';
import '../services/device_service.dart';
import 'device_pairing_flow_screen.dart';

class ManageDeviceScreen extends StatefulWidget {
  const ManageDeviceScreen({super.key});

  @override
  State<ManageDeviceScreen> createState() => _ManageDeviceScreenState();
}

class _ManageDeviceScreenState extends State<ManageDeviceScreen> {
  final DeviceService _deviceService = DeviceService();

  @override
  void initState() {
    super.initState();
    _deviceService.addListener(_onDeviceChanged);
  }

  @override
  void dispose() {
    _deviceService.removeListener(_onDeviceChanged);
    super.dispose();
  }

  void _onDeviceChanged() {
    setState(() {});
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
          'Are you sure you want to disconnect and unpair this ESP32 device? You will need to scan a QR code to pair a device again.',
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

  @override
  Widget build(BuildContext context) {
    final activeDevice = _deviceService.activeDevice;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Manage Device', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (activeDevice != null) ...[
                // Device Specs Header Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF122236),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color:
                                  const Color(0xFF0F766E).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.sensors_rounded,
                                color: Color(0xFF9EEAD9), size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeDevice.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  'Room: ${activeDevice.room}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F9F6E)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle,
                                    size: 12, color: Color(0xFF0F9F6E)),
                                SizedBox(width: 4),
                                Text(
                                  'ONLINE',
                                  style: TextStyle(
                                    color: Color(0xFF0F9F6E),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      _specRow('Scanned Device ID', activeDevice.id),
                      const SizedBox(height: 8),
                      _specRow(
                          'Firebase Location', '/sensors/live/${activeDevice.id}'),
                      const SizedBox(height: 8),
                      _specRow('Connection Type', activeDevice.connectionType),
                      const SizedBox(height: 8),
                      _specRow('MAC Address', activeDevice.macAddress),
                      const SizedBox(height: 8),
                      _specRow(
                          'Signal Strength', '${activeDevice.signalDb} dBm (Good)'),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Device Actions
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_outlined,
                            color: Color(0xFF0F766E)),
                        title: const Text('Rename Device',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: const Text(
                            'Change display label for this sensor node'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _renameDeviceDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.meeting_room_outlined,
                            color: Color(0xFF0F766E)),
                        title: const Text('Change Room Location',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        subtitle:
                            const Text('Update lab, room, or office assignment'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _changeRoomDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.add_a_photo_outlined,
                            color: Color(0xFF0F766E)),
                        title: const Text('Pair Another Device via Camera QR',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F766E))),
                        subtitle:
                            const Text('Scan QR code on esp32_02, esp32_03, etc.'),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: Color(0xFF0F766E)),
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
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.link_off_rounded,
                            color: Color(0xFFD64545)),
                        title: const Text('Unpair Current Device',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD64545))),
                        subtitle: const Text('Disconnect from esp32_01'),
                        onTap: _unpairDeviceConfirm,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No Device State
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.sensors_off_rounded,
                            size: 54, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 14),
                        const Text(
                          'No Device Currently Connected',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Scan the QR code on your physical ESP32 sensor to link live Firebase telemetry.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(fontSize: 13, color: Color(0xFF687386)),
                        ),
                        const SizedBox(height: 24),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scan QR Code to Connect Device',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800)),
      ],
    );
  }
}
