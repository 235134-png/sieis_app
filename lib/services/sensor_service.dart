import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class LiveSensorData {
  final double co2;
  final double voc;
  final double temp;
  final double humidity;
  final double smoke;
  final DateTime lastUpdated;

  LiveSensorData({
    required this.co2,
    required this.voc,
    required this.temp,
    required this.humidity,
    required this.smoke,
    required this.lastUpdated,
  });

  factory LiveSensorData.fromMap(Map<dynamic, dynamic> map) {
    double parseVal(dynamic raw, double fallback) {
      if (raw == null) return fallback;
      if (raw is num) return raw.toDouble();
      if (raw is Map) {
        final m = Map<dynamic, dynamic>.from(raw);
        final val = m['value'] ??
            m['co2'] ??
            m['CO2'] ??
            m['ppm'] ??
            m['reading'] ??
            m['val'] ??
            m['tvoc'] ??
            m['data'] ??
            m['raw'];
        if (val is num) return val.toDouble();
        if (val is String) {
          final p = double.tryParse(val);
          if (p != null) return p;
        }
        for (final v in m.values) {
          if (v is num) return v.toDouble();
          if (v is String) {
            final p = double.tryParse(v);
            if (p != null) return p;
          }
        }
      }
      if (raw is String) {
        final parsed = double.tryParse(raw);
        if (parsed != null) return parsed;
      }
      return fallback;
    }

    final rawCo2 = map['co2'] ?? map['CO2'] ?? map['Co2'];
    final rawTvoc = map['tvoc'] ?? map['voc'] ?? map['VOC'] ?? map['vocs'];
    final rawTemp = map['temperature'] ?? map['temp'] ?? map['Temp'];
    final rawHum = map['humidity'] ?? map['Humidity'];
    final rawSmoke = map['smoke'] ?? map['Smoke'] ?? map['aqi'];

    DateTime updated = DateTime.now();
    if (map['epoch'] != null && map['epoch'] is num) {
      updated = DateTime.fromMillisecondsSinceEpoch(
        (map['epoch'] as num).toInt() * (map['epoch'].toString().length <= 10 ? 1000 : 1),
      );
    } else if (map['timestamp'] != null) {
      try {
        updated = DateTime.parse(map['timestamp'].toString());
      } catch (_) {}
    }

    return LiveSensorData(
      co2: parseVal(rawCo2, 2020),
      voc: parseVal(rawTvoc, 784),
      temp: parseVal(rawTemp, 27.1),
      humidity: parseVal(rawHum, 74),
      smoke: parseVal(rawSmoke, 1998),
      lastUpdated: updated,
    );
  }
}

class SensorService extends ChangeNotifier {
  static final SensorService _instance = SensorService._internal();

  factory SensorService() => _instance;

  SensorService._internal();

  DatabaseReference? _dbRef;
  StreamSubscription<DatabaseEvent>? _rootSubscription;
  StreamSubscription<DatabaseEvent>? _liveSubscription;
  StreamSubscription<DatabaseEvent>? _sensorSubscription;
  StreamSubscription<DatabaseEvent>? _timeSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;

  LiveSensorData _latestData = LiveSensorData(
    co2: 2020,
    voc: 784,
    temp: 27.1,
    humidity: 74,
    smoke: 1998,
    lastUpdated: DateTime.now(),
  );

  bool _isFirebaseConnected = false;
  String? _statusMessage;

  LiveSensorData get latestData => _latestData;
  bool get isFirebaseConnected => _isFirebaseConnected;
  String? get statusMessage => _statusMessage;

  Future<void> initializeFirebaseSensorStream({String deviceId = 'esp32_01'}) async {
    try {
      final app = Firebase.apps.isNotEmpty
          ? Firebase.app()
          : await Firebase.initializeApp();

      final database = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL:
            'https://sieis-7b7fe-default-rtdb.asia-southeast1.firebasedatabase.app',
      );

      // Listen to .info/connected for connection status
      _connectionSubscription?.cancel();
      _connectionSubscription = database.ref('.info/connected').onValue.listen((event) {
        final connected = event.snapshot.value as bool? ?? false;
        _isFirebaseConnected = connected;
        _statusMessage = connected
            ? 'Firebase Live Stream Connected'
            : 'Connecting to Firebase...';
        notifyListeners();
      });

      final targetId = deviceId.trim().isEmpty ? 'esp32_01' : deviceId.trim();

      // 1. ROOT DIRECT STREAM: Listen directly to `database.ref(targetId)` (e.g. /esp32_01)
      _rootSubscription?.cancel();
      _rootSubscription = database.ref(targetId).onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final dataMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _latestData = LiveSensorData.fromMap(dataMap);
          _isFirebaseConnected = true;
          _statusMessage = 'Live Firebase telemetry connected (/$targetId)';
          notifyListeners();
        }
      });

      // 2. SENSORS LIVE STREAM: Listen to `sensors/live/$targetId`
      _liveSubscription?.cancel();
      _liveSubscription = database.ref('sensors/live/$targetId').onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final dataMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _latestData = LiveSensorData.fromMap(dataMap);
          _isFirebaseConnected = true;
          _statusMessage = 'Live Firebase telemetry connected (sensors/live)';
          notifyListeners();
        }
      });

      // 3. DEVICES STREAM: Listen to `devices/$targetId`
      _dbRef = database.ref('devices/$targetId');
      _sensorSubscription?.cancel();
      _sensorSubscription = _dbRef!.onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final dataMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          _latestData = LiveSensorData.fromMap(dataMap);
          _isFirebaseConnected = true;
          _statusMessage = 'Live Firebase telemetry connected';
          notifyListeners();
        }
      });

      // 4. TIME STREAM: Listen to `time` node
      _timeSubscription?.cancel();
      _timeSubscription = database.ref('time').limitToLast(10).onValue.listen((event) {
        if (event.snapshot.value != null && event.snapshot.value is Map) {
          final timeMap = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final keys = timeMap.keys.toList()..sort();

          for (final key in keys.reversed) {
            final child = timeMap[key];
            if (child is Map) {
              final childMap = Map<dynamic, dynamic>.from(child);
              final devId = childMap['deviceId']?.toString() ?? childMap['device_id']?.toString();

              if (devId == targetId || devId == null || targetId == 'esp32_01') {
                _latestData = LiveSensorData.fromMap(childMap);
                _isFirebaseConnected = true;
                notifyListeners();
                break;
              }
            }
          }
        }
      });

    } catch (error) {
      debugPrint('Firebase Initialization Note: $error');
      _statusMessage = 'Listening on local stream';
      _isFirebaseConnected = false;
      notifyListeners();
    }
  }

  void updateDataManually({
    required double co2,
    required double voc,
    required double temp,
    required double humidity,
    required double smoke,
  }) {
    _latestData = LiveSensorData(
      co2: co2,
      voc: voc,
      temp: temp,
      humidity: humidity,
      smoke: smoke,
      lastUpdated: DateTime.now(),
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _rootSubscription?.cancel();
    _liveSubscription?.cancel();
    _sensorSubscription?.cancel();
    _timeSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
