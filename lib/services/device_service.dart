import 'package:flutter/foundation.dart';

class PairedDevice {
  final String id;
  String name;
  final String macAddress;
  String room;
  final String connectionType;
  bool isOnline;
  int signalDb;
  final DateTime pairedAt;

  PairedDevice({
    required this.id,
    required this.name,
    required this.macAddress,
    required this.room,
    required this.connectionType,
    this.isOnline = true,
    this.signalDb = -58,
    DateTime? pairedAt,
  }) : pairedAt = pairedAt ?? DateTime.now();
}

class DeviceService extends ChangeNotifier {
  static final DeviceService _instance = DeviceService._internal();

  factory DeviceService() => _instance;

  DeviceService._internal() {
    // Default to no paired device initially so user connects device during setup
    _activeDevice = null;
  }

  PairedDevice? _activeDevice;

  bool get isDevicePaired => _activeDevice != null;
  PairedDevice? get activeDevice => _activeDevice;

  void pairDevice(PairedDevice device) {
    _activeDevice = device;
    notifyListeners();
  }

  void unpairDevice() {
    _activeDevice = null;
    notifyListeners();
  }

  void updateDeviceRoom(String room) {
    if (_activeDevice != null) {
      _activeDevice!.room = room;
      notifyListeners();
    }
  }

  void renameDevice(String newName) {
    if (_activeDevice != null) {
      _activeDevice!.name = newName;
      notifyListeners();
    }
  }
}
