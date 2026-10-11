import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/device_service.dart';
import '../services/sensor_service.dart';

class DevicePairingFlowScreen extends StatefulWidget {
  const DevicePairingFlowScreen({
    super.key,
    required this.onPairingComplete,
    this.allowSkip = false,
  });

  final VoidCallback onPairingComplete;
  final bool allowSkip;

  @override
  State<DevicePairingFlowScreen> createState() => _DevicePairingFlowScreenState();
}

enum PairingStep { selection, scanning, manualInput, confirmation }

class _DevicePairingFlowScreenState extends State<DevicePairingFlowScreen> {
  PairingStep _step = PairingStep.selection;
  final _manualIdController = TextEditingController(text: 'esp32_01');
  final _roomController = TextEditingController(text: 'Computer Lab A');
  final MobileScannerController _cameraController = MobileScannerController();

  String _detectedDeviceId = 'esp32_01';
  String _detectedDeviceName = 'ESP32 Indoor Air Sensor';
  bool _isConnecting = false;
  bool _hasScanned = false;

  @override
  void dispose() {
    _manualIdController.dispose();
    _roomController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  void _startQrScan() {
    setState(() {
      _hasScanned = false;
      _step = PairingStep.scanning;
    });
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        _hasScanned = true;
        String parsedId = rawValue.trim();

        // Handle JSON payloads if device QR contains JSON e.g. {"id":"ESP32-8401"}
        if (parsedId.contains('"id"')) {
          final idMatch = RegExp(r'"id"\s*:\s*"([^"]+)"').firstMatch(parsedId);
          if (idMatch != null && idMatch.group(1) != null) {
            parsedId = idMatch.group(1)!;
          }
        }

        if (mounted) {
          setState(() {
            _detectedDeviceId = parsedId;
            _detectedDeviceName = 'ESP32 Sensor $parsedId';
            _step = PairingStep.confirmation;
          });
        }
        break;
      }
    }
  }

  void _submitManualId() {
    final text = _manualIdController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _detectedDeviceId = text;
      _detectedDeviceName = 'ESP32 Sensor $text';
      _step = PairingStep.confirmation;
    });
  }

  void _confirmAndConnectDevice() {
    setState(() => _isConnecting = true);

    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;

      final paired = PairedDevice(
        id: _detectedDeviceId,
        name: _detectedDeviceName,
        macAddress: '24:62:AB:${_detectedDeviceId.hashCode.toRadixString(16).padLeft(4, '0').substring(0, 4).toUpperCase()}',
        room: _roomController.text.trim().isEmpty
            ? 'Main Room'
            : _roomController.text.trim(),
        connectionType: 'Wi-Fi Direct',
        isOnline: true,
        signalDb: -56,
      );

      // 1. Save paired device state
      DeviceService().pairDevice(paired);

      // 2. Connect SensorService stream to this scanned device ID in Firebase!
      await SensorService().initializeFirebaseSensorStream(deviceId: paired.id);

      if (!mounted) return;
      setState(() => _isConnecting = false);
      widget.onPairingComplete();
    });
  }

  void _showTroubleshootDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.build_circle_outlined, color: Color(0xFFE09B22)),
            SizedBox(width: 8),
            Text('Device Troubleshooting', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('If your ESP32 device is not connecting or QR scan fails, follow these steps:',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
              SizedBox(height: 12),
              Text('1. Check Power', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('Ensure the ESP32 power LED is turned on.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              SizedBox(height: 10),
              Text('2. Firebase Path Match', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('Ensure your ESP32 uploads data to path "devices/<device_id>" in Firebase.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              SizedBox(height: 10),
              Text('3. Use Manual Device ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              Text('If the camera QR scan is unavailable, tap "Enter Device ID Manually" and type e.g. ESP32-8401.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Connect Device',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: _step != PairingStep.selection,
        leading: _step != PairingStep.selection
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() => _step = PairingStep.selection);
                },
              )
            : null,
        actions: [
          IconButton(
            tooltip: 'Troubleshoot Device',
            icon: const Icon(Icons.help_outline_rounded, color: Color(0xFF0F766E)),
            onPressed: _showTroubleshootDialog,
          ),
          if (widget.allowSkip)
            TextButton(
              onPressed: widget.onPairingComplete,
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepView(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_step) {
      case PairingStep.selection:
        return _buildSelectionStep();
      case PairingStep.scanning:
        return _buildScanningStep();
      case PairingStep.manualInput:
        return _buildManualInputStep();
      case PairingStep.confirmation:
        return _buildConfirmationStep();
    }
  }

  Widget _buildSelectionStep() {
    return Column(
      key: const ValueKey('selection_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2F1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              size: 40,
              color: Color(0xFF0F766E),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Pair Your SIEIS Device',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF162033),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Scan the QR code on your physical ESP32 sensor or enter the Device ID to connect live Firebase telemetry.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF687386),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),

        // Scan QR Button Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF0F766E), width: 1.5),
          ),
          child: InkWell(
            onTap: _startQrScan,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan Camera QR Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Point camera at your ESP32 QR sticker',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF687386),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF0F766E),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Manual Input Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: InkWell(
            onTap: () {
              setState(() => _step = PairingStep.manualInput);
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.edit_note_rounded,
                      color: Color(0xFF374151),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enter Device ID Manually',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Type the Device ID (e.g. ESP32-8401)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF687386),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: _showTroubleshootDialog,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4B5563),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          icon: const Icon(Icons.build_outlined, size: 18),
          label: const Text('Device Not Working? Troubleshoot'),
        ),
      ],
    );
  }

  Widget _buildScanningStep() {
    return Column(
      key: const ValueKey('scanning_step'),
      children: [
        Container(
          height: 340,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(
                  controller: _cameraController,
                  onDetect: _onBarcodeDetected,
                ),

                // Target Frame Overlay
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2DD4BF), width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                Positioned(
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2DD4BF)),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Point camera at ESP32 QR code...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _step = PairingStep.selection);
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Instant test scan trigger if testing on emulator without camera
                  setState(() {
                    _detectedDeviceId = 'esp32_01';
                    _detectedDeviceName = 'ESP32 Air Sensor (esp32_01)';
                    _step = PairingStep.confirmation;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: const Text('Test Pairing'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManualInputStep() {
    return Card(
      key: const ValueKey('manual_step'),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter Device ID',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Type the ESP32 Device ID corresponding to your Firebase path (e.g., ESP32-8401).',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF687386),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _manualIdController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Device Identifier',
                hintText: 'e.g. ESP32-8401',
                prefixIcon: const Icon(Icons.qr_code_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitManualId,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Continue to Confirmation',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Column(
      key: const ValueKey('confirmation_step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7EF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF0F9F6E).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF0F9F6E),
                size: 32,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESP32 Device Identified',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Ready to bind live Firebase stream',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Device Specifications',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const Divider(height: 24),
                _infoRow('Device Name', _detectedDeviceName),
                const SizedBox(height: 10),
                _infoRow('Scanned Device ID', _detectedDeviceId),
                const SizedBox(height: 10),
                _infoRow('Firebase Path', 'devices/$_detectedDeviceId'),
                const SizedBox(height: 20),

                // Room Location Assignment
                TextField(
                  controller: _roomController,
                  decoration: InputDecoration(
                    labelText: 'Room / Location Name',
                    hintText: 'e.g. Computer Lab A, Bedroom, Office',
                    prefixIcon: const Icon(Icons.meeting_room_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _showTroubleshootDialog,
              icon: const Icon(Icons.build_outlined, size: 16),
              label: const Text('Device not working? Troubleshoot'),
            ),
          ],
        ),

        const SizedBox(height: 14),

        ElevatedButton(
          onPressed: _isConnecting ? null : _confirmAndConnectDevice,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isConnecting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Connect $_detectedDeviceId & View Dashboard',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
