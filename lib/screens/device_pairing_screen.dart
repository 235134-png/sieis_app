import 'package:flutter/material.dart';

class PairedDevice {
  final String id;
  final String name;
  final String macAddress;
  final String connectionType;
  final bool isOnline;
  final int signalDb;

  PairedDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.connectionType,
    required this.isOnline,
    required this.signalDb,
  });
}

class DevicePairingScreen extends StatefulWidget {
  const DevicePairingScreen({super.key});

  @override
  State<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends State<DevicePairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _deviceIdController = TextEditingController();
  final _wifiSsidController = TextEditingController(text: 'Lab_AirNet_5G');
  final _wifiPasswordController = TextEditingController();

  bool _isConnecting = false;
  String? _statusMessage;

  final List<PairedDevice> _pairedDevices = [
    PairedDevice(
      id: 'ESP32-8401',
      name: 'Computer Lab A - ESP32 Node 1',
      macAddress: '24:62:AB:F1:84:01',
      connectionType: 'Wi-Fi (192.168.1.104)',
      isOnline: true,
      signalDb: -58,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _deviceIdController.dispose();
    _wifiSsidController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _addDevice(String id, String name, String type) {
    setState(() {
      _isConnecting = true;
      _statusMessage = null;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _isConnecting = false;
        final newDevice = PairedDevice(
          id: id,
          name: name,
          macAddress: '24:62:AB:${id.hashCode.toRadixString(16).substring(0, 4).toUpperCase()}',
          connectionType: type,
          isOnline: true,
          signalDb: -62,
        );
        _pairedDevices.add(newDevice);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully paired $name ($id)'),
          backgroundColor: const Color(0xFF0F9F6E),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  void _removeDevice(PairedDevice device) {
    setState(() {
      _pairedDevices.removeWhere((d) => d.id == device.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed ${device.name}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'ESP32 Device Pairing',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0F766E),
          unselectedLabelColor: const Color(0xFF687386),
          indicatorColor: const Color(0xFF0F766E),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner_rounded), text: 'QR Code'),
            Tab(icon: Icon(Icons.wifi_rounded), text: 'Wi-Fi Provision'),
            Tab(icon: Icon(Icons.pin_rounded), text: 'Device ID'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQrScanTab(),
                _buildWifiTab(),
                _buildDeviceIdTab(),
              ],
            ),
          ),
          _buildPairedDevicesList(),
        ],
      ),
    );
  }

  Widget _buildQrScanTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Camera simulation pattern
                  Icon(
                    Icons.center_focus_weak_rounded,
                    size: 140,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF0F766E), width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Align ESP32 QR code within frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isConnecting
                ? null
                : () => _addDevice('ESP32-QR99', 'ESP32 Air Sensor QR', 'QR Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: _isConnecting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.qr_code_2_rounded),
            label: Text(
              _isConnecting ? 'Connecting to ESP32...' : 'Simulate Scanning ESP32 QR',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWifiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.wifi_find_rounded, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESP32 SoftAP Provisioning',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Connect ESP32 to local Wi-Fi network',
                          style: TextStyle(color: Color(0xFF687386), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _wifiSsidController,
                decoration: InputDecoration(
                  labelText: 'Target Wi-Fi SSID',
                  prefixIcon: const Icon(Icons.wifi_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _wifiPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Wi-Fi Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isConnecting
                    ? null
                    : () {
                        if (_wifiSsidController.text.isEmpty) return;
                        _addDevice('ESP32-WF55', 'ESP32 Room Sensor', 'Wi-Fi Direct');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.settings_input_antenna_rounded),
                label: const Text(
                  'Provision & Connect ESP32',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIdTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2F1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.developer_board_rounded, color: Color(0xFF0F766E)),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manual Device ID',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          'Enter the ID printed on the ESP32 enclosure',
                          style: TextStyle(color: Color(0xFF687386), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _deviceIdController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'ESP32 Device ID',
                  hintText: 'e.g. ESP32-90A4-LAB',
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isConnecting
                    ? null
                    : () {
                        final text = _deviceIdController.text.trim();
                        final id = text.isEmpty ? 'ESP32-90A4' : text;
                        _addDevice(id, 'ESP32 Node $id', 'Device ID');
                        _deviceIdController.clear();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.link_rounded),
                label: const Text(
                  'Pair Device',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPairedDevicesList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Paired ESP32 Devices',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_pairedDevices.length}',
                  style: const TextStyle(
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_pairedDevices.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No ESP32 devices paired yet. Choose a method above to pair a sensor.',
                style: TextStyle(color: Color(0xFF687386), fontSize: 13),
              ),
            )
          else
            Column(
              children: _pairedDevices
                  .map(
                    (device) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F9F6E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${device.id} • ${device.macAddress}',
                                  style: const TextStyle(
                                    color: Color(0xFF687386),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD64545)),
                            onPressed: () => _removeDevice(device),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
