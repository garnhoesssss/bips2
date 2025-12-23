import 'package:google_maps_flutter/google_maps_flutter.dart';

/// ============================================
/// BUS DATA MODEL
/// Adapter for Supabase bipol_tracker table
/// ============================================

enum BusStatus {
  onRoute,
  atStop,
  delayed,
  offline,
}

/// Mapping from database bus_id to UI display names
class BusIdMapping {
  // Database ID → UI Display Name
  static const Map<String, String> dbToDisplay = {
    'BPL-BIPOL': 'BUS-01',
    'B 2013 EPA': 'BUS-02',
    'B 2027 EPA': 'BUS-03',
  };

  // UI Display Name → Database ID
  static const Map<String, String> displayToDb = {
    'BUS-01': 'BPL-BIPOL',
    'BUS-02': 'B 2013 EPA',
    'BUS-03': 'B 2027 EPA',
  };

  /// Get the display name for a database ID
  static String getDisplayName(String dbId) {
    return dbToDisplay[dbId] ?? dbId;
  }

  /// Get the database ID for a display name
  static String getDbId(String displayName) {
    return displayToDb[displayName] ?? displayName;
  }

  /// Check if a bus has a gas sensor (only BPL-BIPOL / BUS-01)
  static bool hasGasSensor(String dbId) {
    return dbId == 'BPL-BIPOL';
  }

  /// Order for displaying buses (BUS-01, BUS-02, BUS-03)
  static int getDisplayOrder(String dbId) {
    switch (dbId) {
      case 'BPL-BIPOL':
        return 0;
      case 'B 2013 EPA':
        return 1;
      case 'B 2027 EPA':
        return 2;
      default:
        return 99;
    }
  }
}

class BusModel {
  final String dbBusId;      // Original ID from database
  final String displayId;    // UI display name (BUS-01, BUS-02, BUS-03)
  final double latitude;
  final double longitude;
  final double speed;
  final int gasLevel;
  final bool isOnline;
  final DateTime lastUpdated;
  final String routeName;
  final String? nextStop;
  final String? followingStop;
  final int? etaMinutes;
  final BusStatus status;

  BusModel({
    required this.dbBusId,
    required this.displayId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.gasLevel,
    required this.isOnline,
    required this.lastUpdated,
    this.routeName = 'Campus Route',
    this.nextStop,
    this.followingStop,
    this.etaMinutes,
    this.status = BusStatus.onRoute,
  });

  /// Convenience getter for backward compatibility (returns display ID)
  String get busId => displayId;

  LatLng get position => LatLng(latitude, longitude);

  /// Check if air quality is safe (gas level < 500)
  bool get isAirQualitySafe => gasLevel < 500;

  /// Check if this bus has a gas sensor (only BUS-01 / BPL-BIPOL)
  bool get hasGasSensor => BusIdMapping.hasGasSensor(dbBusId);

  /// Get descriptive air quality text
  String get airQualityText {
    if (!hasGasSensor) return 'No Sensor';
    if (gasLevel < 300) return 'Good';
    if (gasLevel < 500) return 'Normal';
    return 'SMOKE DETECTED';
  }

  /// Factory constructor to parse data from Supabase bipol_tracker table
  /// Schema: id, bus_id, latitude, longitude, speed, gas_level, created_at
  factory BusModel.fromSupabase(Map<String, dynamic> json) {
    final dbId = json['bus_id'] as String? ?? 'UNKNOWN';
    final displayName = BusIdMapping.getDisplayName(dbId);
    final hasGas = BusIdMapping.hasGasSensor(dbId);
    
    // Parse created_at for lastUpdated
    DateTime lastUpdated;
    if (json['created_at'] != null) {
      lastUpdated = DateTime.parse(json['created_at'] as String);
    } else {
      lastUpdated = DateTime.now();
    }
    
    // Determine online status based on data freshness (5 minutes threshold)
    final isOnline = DateTime.now().difference(lastUpdated).inMinutes < 5;
    
    // Determine status based on speed and online status
    BusStatus status;
    if (!isOnline) {
      status = BusStatus.offline;
    } else {
      final speed = (json['speed'] as num?)?.toDouble() ?? 0.0;
      if (speed > 5) {
        status = BusStatus.onRoute;
      } else if (speed > 0) {
        status = BusStatus.atStop;
      } else {
        status = BusStatus.atStop;
      }
    }
    
    // Gas level: only valid for BPL-BIPOL, default 0 for others
    final gasLevel = hasGas ? ((json['gas_level'] as num?)?.toInt() ?? 0) : 0;
    
    return BusModel(
      dbBusId: dbId,
      displayId: displayName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      gasLevel: gasLevel,
      isOnline: isOnline,
      lastUpdated: lastUpdated,
      routeName: _getRouteName(displayName),
      nextStop: _getDefaultNextStop(displayName),
      followingStop: _getDefaultFollowingStop(displayName),
      etaMinutes: null,
      status: status,
    );
  }

  /// Get route name based on bus display ID
  static String _getRouteName(String displayId) {
    switch (displayId) {
      case 'BUS-01':
        return 'Sensor Unit • Main Campus';
      case 'BUS-02':
        return 'North Campus Loop';
      case 'BUS-03':
        return 'South Campus Loop';
      default:
        return 'Campus Route';
    }
  }

  /// Get default next stop (placeholder - can be enhanced later)
  static String? _getDefaultNextStop(String displayId) {
    switch (displayId) {
      case 'BUS-01':
        return 'Fakultas Teknik';
      case 'BUS-02':
        return 'Fakultas MIPA';
      case 'BUS-03':
        return 'Rektorat';
      default:
        return null;
    }
  }

  /// Get default following stop (placeholder - can be enhanced later)
  static String? _getDefaultFollowingStop(String displayId) {
    switch (displayId) {
      case 'BUS-01':
        return 'Perpustakaan Pusat';
      case 'BUS-02':
        return 'Fakultas Hukum';
      case 'BUS-03':
        return 'Fakultas Ekonomi';
      default:
        return null;
    }
  }

  /// Legacy factory for backward compatibility
  factory BusModel.fromJson(Map<String, dynamic> json) {
    return BusModel.fromSupabase(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': dbBusId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'gas_level': gasLevel,
      'created_at': lastUpdated.toIso8601String(),
    };
  }

  /// Create a copy with updated values
  BusModel copyWith({
    String? dbBusId,
    String? displayId,
    double? latitude,
    double? longitude,
    double? speed,
    int? gasLevel,
    bool? isOnline,
    DateTime? lastUpdated,
    String? routeName,
    String? nextStop,
    String? followingStop,
    int? etaMinutes,
    BusStatus? status,
  }) {
    return BusModel(
      dbBusId: dbBusId ?? this.dbBusId,
      displayId: displayId ?? this.displayId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      gasLevel: gasLevel ?? this.gasLevel,
      isOnline: isOnline ?? this.isOnline,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      routeName: routeName ?? this.routeName,
      nextStop: nextStop ?? this.nextStop,
      followingStop: followingStop ?? this.followingStop,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      status: status ?? this.status,
    );
  }

  /// Create dummy data for testing (fallback when no real data)
  static List<BusModel> getDummyBuses() {
    return [
      BusModel(
        dbBusId: 'BPL-BIPOL',
        displayId: 'BUS-01',
        latitude: -6.365,
        longitude: 106.824,
        speed: 42,
        gasLevel: 320,
        isOnline: true,
        lastUpdated: DateTime.now(),
        routeName: 'Sensor Unit • Main Campus',
        nextStop: 'Fakultas Teknik',
        followingStop: 'Perpustakaan Pusat',
        etaMinutes: 4,
        status: BusStatus.onRoute,
      ),
      BusModel(
        dbBusId: 'B 2013 EPA',
        displayId: 'BUS-02',
        latitude: -6.366,
        longitude: 106.825,
        speed: 0,
        gasLevel: 0,
        isOnline: true,
        lastUpdated: DateTime.now(),
        routeName: 'North Campus Loop',
        nextStop: 'Fakultas MIPA',
        followingStop: 'Fakultas Hukum',
        etaMinutes: 2,
        status: BusStatus.atStop,
      ),
      BusModel(
        dbBusId: 'B 2027 EPA',
        displayId: 'BUS-03',
        latitude: -6.364,
        longitude: 106.823,
        speed: 15,
        gasLevel: 0,
        isOnline: true,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
        routeName: 'South Campus Loop',
        nextStop: 'Rektorat',
        followingStop: 'Fakultas Ekonomi',
        etaMinutes: 8,
        status: BusStatus.delayed,
      ),
    ];
  }

  @override
  String toString() {
    return 'BusModel(displayId: $displayId, dbBusId: $dbBusId, lat: $latitude, lng: $longitude, speed: $speed, gasLevel: $gasLevel, status: $status)';
  }
}
