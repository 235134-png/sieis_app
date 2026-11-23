import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

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
    _activeDevice = null;
  }

  PairedDevice? _activeDevice;

  bool get isDevicePaired => _activeDevice != null;
  PairedDevice? get activeDevice => _activeDevice;

  Future<void> syncDeviceToFirebase() async {
    final userId = AuthService().currentUser?.id;
    if (userId == null || _activeDevice == null) return;
    try {
      final app = Firebase.apps.isNotEmpty
          ? Firebase.app()
          : await Firebase.initializeApp();
      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://sieis-7b7fe-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await database
          .ref('users/$userId/paired_devices/${_activeDevice!.id}')
          .set({
        'deviceId': _activeDevice!.id,
        'deviceName': _activeDevice!.name,
        'roomLocation': _activeDevice!.room,
        'macAddress': _activeDevice!.macAddress,
        'connectionType': _activeDevice!.connectionType,
        'isOnline': _activeDevice!.isOnline,
        'signalDb': _activeDevice!.signalDb,
        'pairedAt': _activeDevice!.pairedAt.millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('Firebase Device Sync Note: $e');
    }
  }

  Future<void> removeDeviceFromFirebase(String deviceId) async {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return;
    try {
      final app = Firebase.apps.isNotEmpty
          ? Firebase.app()
          : await Firebase.initializeApp();
      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://sieis-7b7fe-default-rtdb.asia-southeast1.firebasedatabase.app',
      );
      await database.ref('users/$userId/paired_devices/$deviceId').remove();
    } catch (e) {
      debugPrint('Firebase Device Remove Note: $e');
    }
  }

  void pairDevice(PairedDevice device) {
    _activeDevice = device;
    notifyListeners();
    syncDeviceToFirebase();
  }

  void unpairDevice() {
    if (_activeDevice != null) {
      final oldId = _activeDevice!.id;
      _activeDevice = null;
      notifyListeners();
      removeDeviceFromFirebase(oldId);
    }
  }

  void updateDeviceRoom(String room) {
    if (_activeDevice != null) {
      _activeDevice!.room = room;
      notifyListeners();
      syncDeviceToFirebase();
    }
  }

  void renameDevice(String newName) {
    if (_activeDevice != null) {
      _activeDevice!.name = newName;
      notifyListeners();
      syncDeviceToFirebase();
    }
  }
}
