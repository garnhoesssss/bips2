import 'dart:async';
import 'dart:math' show cos, sqrt, asin, pi, sin, atan2;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants.dart';
import '../models/bus_model.dart';
import '../widgets/bus_bottom_sheet.dart';

/// ============================================
/// HOME MAP PAGE - FLEET COMMAND DESIGN
/// Real-time Supabase Integration + Smooth Animation
/// ============================================

class HomeMapPage extends StatefulWidget {
  const HomeMapPage({super.key});

  @override
  State<HomeMapPage> createState() => _HomeMapPageState();
}

class _HomeMapPageState extends State<HomeMapPage> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  BusModel? _selectedBus;
  List<BusModel> _buses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isFirstLoad = true;

  // Custom marker icons loaded from assets
  BitmapDescriptor? _busMarkerIcon;
  BitmapDescriptor? _halteMarkerIcon;

  StreamSubscription<List<Map<String, dynamic>>>? _busStreamSubscription;

  // Smooth marker animation system
  late AnimationController _markerAnimationController;
  Map<String, LatLng> _busCurrentPositions = {};   // Current animated position
  Map<String, LatLng> _busTargetPositions = {};    // Target from Supabase
  Map<String, LatLng> _busStartPositions = {};     // Start of animation
  Map<String, double> _busBearings = {};           // Direction bus is facing

  // Auto-refresh timer for polling fresh data
  Timer? _autoRefreshTimer;

  // Default center: Universitas Indonesia
  static const LatLng _defaultCenter = LatLng(-6.365, 106.824);

  // Bus stop data (positions only - markers built dynamically)
  static const List<Map<String, dynamic>> _busStopData = [
    {'id': 'stop_menwa', 'title': 'Halte Menwa', 'lat': -6.353451234067877, 'lng': 106.83180708392858},
    {'id': 'stop_st_ui', 'title': 'Halte Stasiun UI', 'lat': -6.360918183407223, 'lng': 106.83169970032718},
    {'id': 'stop_pocin', 'title': 'Halte St. Pondok Cina', 'lat': -6.3682916937343395, 'lng': 106.83169462877837},
    {'id': 'stop_pnj', 'title': 'Halte PNJ', 'lat': -6.371320205307198, 'lng': 106.82395973968354},
  ];

  /// Build bus stop markers with custom icon
  Set<Marker> _buildBusStopMarkers() {
    return _busStopData.map((stop) {
      return Marker(
        markerId: MarkerId(stop['id'] as String),
        position: LatLng(stop['lat'] as double, stop['lng'] as double),
        infoWindow: InfoWindow(title: stop['title'] as String),
        icon: _halteMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      );
    }).toSet();
  }

  // Hardcoded route polylines
  final Set<Polyline> _routeLines = {
    // --- MORNING ROUTE (PAGI) ---
    Polyline(
      polylineId: const PolylineId('rute_pagi'),
      color: const Color(0xFFBF1E2E), // Deep Red
      width: 6,
      points: const [
        LatLng(-6.371652, 106.824426), LatLng(-6.371666, 106.824062), LatLng(-6.371629, 106.824008),
        LatLng(-6.371385, 106.823979), LatLng(-6.371125, 106.823963), LatLng(-6.370600, 106.823949),
        LatLng(-6.370250, 106.823928), LatLng(-6.370231, 106.824195), LatLng(-6.366948, 106.824034),
        LatLng(-6.366927, 106.823076), LatLng(-6.366928, 106.822951), LatLng(-6.366877, 106.822650),
        LatLng(-6.366740, 106.822386), LatLng(-6.366135, 106.821714), LatLng(-6.365903, 106.821530),
        LatLng(-6.365745, 106.821451), LatLng(-6.365717, 106.821442), LatLng(-6.365443, 106.821432),
        LatLng(-6.365228, 106.821522), LatLng(-6.361813, 106.822580), LatLng(-6.361566, 106.822677),
        LatLng(-6.360561, 106.823005), LatLng(-6.349295, 106.826464), LatLng(-6.348881, 106.826629),
        LatLng(-6.348645, 106.826790), LatLng(-6.348504, 106.826990), LatLng(-6.348184, 106.827629),
        LatLng(-6.348127, 106.827811), LatLng(-6.348124, 106.828147), LatLng(-6.348686, 106.831320),
        LatLng(-6.348812, 106.831612), LatLng(-6.348996, 106.831796), LatLng(-6.349149, 106.831895),
        LatLng(-6.349399, 106.831942), LatLng(-6.349586, 106.831914), LatLng(-6.351188, 106.831549),
        LatLng(-6.351352, 106.831549), LatLng(-6.351778, 106.831697), LatLng(-6.352011, 106.831814),
        LatLng(-6.352413, 106.831923), LatLng(-6.353014, 106.831900), LatLng(-6.354139, 106.831666),
        LatLng(-6.354333, 106.831585), LatLng(-6.355903, 106.830348), LatLng(-6.356067, 106.830261),
        LatLng(-6.356229, 106.830203), LatLng(-6.356540, 106.830191), LatLng(-6.356738, 106.830222),
        LatLng(-6.356883, 106.830275), LatLng(-6.357058, 106.830392), LatLng(-6.358062, 106.831169),
        LatLng(-6.358205, 106.831212), LatLng(-6.362196, 106.831831), LatLng(-6.362686, 106.831888),
        LatLng(-6.363206, 106.831966), LatLng(-6.364137, 106.832148), LatLng(-6.364463, 106.832186),
        LatLng(-6.364786, 106.832193), LatLng(-6.367655, 106.832138), LatLng(-6.367807, 106.832100),
        LatLng(-6.368703, 106.831215), LatLng(-6.368848, 106.831099), LatLng(-6.369117, 106.831046),
        LatLng(-6.369896, 106.831000), LatLng(-6.370508, 106.830979), LatLng(-6.370763, 106.830919),
        LatLng(-6.371013, 106.830771), LatLng(-6.371238, 106.830558), LatLng(-6.371645, 106.829893),
        LatLng(-6.371673, 106.829722), LatLng(-6.371641, 106.828571), LatLng(-6.371628, 106.827776),
        LatLng(-6.371581, 106.827547), LatLng(-6.371360, 106.827226), LatLng(-6.369323, 106.825329),
        LatLng(-6.369027, 106.825098), LatLng(-6.368752, 106.825022), LatLng(-6.368542, 106.824992),
        LatLng(-6.367234, 106.824979), LatLng(-6.367144, 106.824956), LatLng(-6.367000, 106.824806),
        LatLng(-6.366929, 106.824624), LatLng(-6.366934, 106.824199), LatLng(-6.367734, 106.824222),
        LatLng(-6.370610, 106.824368), LatLng(-6.370678, 106.824415), LatLng(-6.371102, 106.824417),
        LatLng(-6.371366, 106.824410), LatLng(-6.371654, 106.824430),
      ],
    ),
    // --- AFTERNOON ROUTE (SORE) ---
    Polyline(
      polylineId: const PolylineId('rute_sore'),
      color: const Color(0xFF159BB3), // Cyan/Teal
      width: 6,
      points: const [
        LatLng(-6.351814, 106.831697), LatLng(-6.352137, 106.831863), LatLng(-6.352489, 106.831920),
        LatLng(-6.352952, 106.831879), LatLng(-6.354154, 106.831673), LatLng(-6.355982, 106.830275),
        LatLng(-6.356449, 106.830157), LatLng(-6.356934, 106.830284), LatLng(-6.358163, 106.831209),
        LatLng(-6.362697, 106.831871), LatLng(-6.363241, 106.831955), LatLng(-6.364361, 106.832169),
        LatLng(-6.364643, 106.832180), LatLng(-6.367669, 106.832126), LatLng(-6.367791, 106.832097),
        LatLng(-6.367906, 106.832024), LatLng(-6.368770, 106.831142), LatLng(-6.368884, 106.831072),
        LatLng(-6.370622, 106.830954), LatLng(-6.370801, 106.830900), LatLng(-6.371273, 106.830509),
        LatLng(-6.371675, 106.829755), LatLng(-6.371609, 106.827644), LatLng(-6.371366, 106.827234),
        LatLng(-6.369023, 106.825107), LatLng(-6.368711, 106.825008), LatLng(-6.367202, 106.824992),
        LatLng(-6.367021, 106.824868), LatLng(-6.366925, 106.824643), LatLng(-6.366933, 106.824187),
        LatLng(-6.370596, 106.824361), LatLng(-6.370686, 106.824404), LatLng(-6.371635, 106.824423),
        LatLng(-6.371653, 106.824062), LatLng(-6.371604, 106.824007), LatLng(-6.371159, 106.823978),
        LatLng(-6.370263, 106.823942), LatLng(-6.370237, 106.824207), LatLng(-6.366937, 106.824042),
        LatLng(-6.366918, 106.822922), LatLng(-6.366770, 106.822439), LatLng(-6.365893, 106.821538),
        LatLng(-6.365460, 106.821445), LatLng(-6.363840, 106.821978), LatLng(-6.363858, 106.822061),
        LatLng(-6.365354, 106.821599), LatLng(-6.365646, 106.821573), LatLng(-6.365879, 106.821670),
        LatLng(-6.366674, 106.822449), LatLng(-6.366843, 106.822984), LatLng(-6.366860, 106.824922),
        LatLng(-6.367109, 106.825128), LatLng(-6.368654, 106.825088), LatLng(-6.368965, 106.825182),
        LatLng(-6.371310, 106.827334), LatLng(-6.371536, 106.827731), LatLng(-6.371583, 106.829861),
        LatLng(-6.371206, 106.830465), LatLng(-6.370821, 106.830775), LatLng(-6.370522, 106.830884),
        LatLng(-6.369008, 106.830933), LatLng(-6.368784, 106.831022), LatLng(-6.367819, 106.831985),
        LatLng(-6.367664, 106.832055), LatLng(-6.364487, 106.832105), LatLng(-6.363674, 106.831961),
        LatLng(-6.363386, 106.831781), LatLng(-6.363010, 106.831666), LatLng(-6.362749, 106.831655),
        LatLng(-6.362410, 106.831768), LatLng(-6.358165, 106.831079), LatLng(-6.357987, 106.831009),
        LatLng(-6.356843, 106.830148), LatLng(-6.356521, 106.830076), LatLng(-6.356134, 106.830124),
        LatLng(-6.355881, 106.830258), LatLng(-6.354294, 106.831477), LatLng(-6.354008, 106.831595),
        LatLng(-6.352601, 106.831837), LatLng(-6.352337, 106.831831), LatLng(-6.351833, 106.831649),
        LatLng(-6.351814, 106.831697),
      ],
    ),
  };

  @override
  void initState() {
    super.initState();
    
    // Initialize smooth marker animation controller
    _markerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500), // Slightly faster than GPS update interval
    );
    _markerAnimationController.addListener(_onMarkerAnimationTick);
    
    _loadCustomMarkerIcons();
    _initBusStream();
    
    // Start auto-refresh timer (1 second interval)
    _startAutoRefresh();
  }

  /// Start auto-refresh timer to poll fresh data every 5 seconds
  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchLatestData();
    });
  }

  /// Fetch latest data from Supabase (called by auto-refresh timer)
  Future<void> _fetchLatestData() async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('bipol_tracker')
          .select()
          .order('created_at', ascending: false)
          .limit(100);
      
      if (data.isNotEmpty && mounted) {
        _processStreamData(List<Map<String, dynamic>>.from(data));
      }
    } catch (e) {
      debugPrint('⚠️ Auto-refresh error: $e');
    }
  }

  /// Load custom marker icons from assets
  Future<void> _loadCustomMarkerIcons() async {
    try {
      final busIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/marker_bus.png',
      );
      final halteIcon = await BitmapDescriptor.asset(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/images/marker_halte.png',
      );
      if (mounted) {
        setState(() {
          _busMarkerIcon = busIcon;
          _halteMarkerIcon = halteIcon;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load custom markers: $e');
      // Fallback to default markers if loading fails - no action needed
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _markerAnimationController.dispose();
    _busStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Initialize real-time stream from Supabase bipol_tracker table
  void _initBusStream() {
    try {
      final supabase = Supabase.instance.client;

      // Stream all data from bipol_tracker, ordered by created_at desc
      _busStreamSubscription = supabase
          .from('bipol_tracker')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
        (data) {
          debugPrint('📥 Received ${data.length} rows from bipol_tracker');
          _processStreamData(data);
        },
        onError: (error) {
          debugPrint('❌ Stream error: $error');
          setState(() {
            _hasError = true;
            _errorMessage = 'Failed to connect to database';
            _isLoading = false;
          });
          // Fallback to dummy data
          _loadDummyBuses();
        },
      );
    } catch (e) {
      debugPrint('❌ Failed to initialize stream: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize stream: $e';
        _isLoading = false;
      });
      _loadDummyBuses();
    }
  }

  /// Process streamed data and group by bus_id to get latest row for each bus
  void _processStreamData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      debugPrint('⚠️ No data received, loading dummy buses');
      _loadDummyBuses();
      return;
    }

    // Group by bus_id and get the most recent entry for each
    final Map<String, Map<String, dynamic>> latestByBusId = {};
    
    for (final row in data) {
      final busId = row['bus_id'] as String?;
      if (busId == null) continue;
      
      // Only keep if this bus_id not yet seen (data is ordered by created_at desc)
      if (!latestByBusId.containsKey(busId)) {
        latestByBusId[busId] = row;
      }
    }

    // Convert to BusModel list
    List<BusModel> buses = latestByBusId.values
        .map((row) => BusModel.fromSupabase(row))
        .toList();

    // Sort by display order (BUS-01, BUS-02, BUS-03)
    buses.sort((a, b) => 
        BusIdMapping.getDisplayOrder(a.dbBusId)
            .compareTo(BusIdMapping.getDisplayOrder(b.dbBusId)));

    // Calculate ETA and nearest stop for each bus
    buses = buses.map((bus) {
      final nearestStopResult = _findNearestStopByPath(bus);
      final nearestStopName = nearestStopResult['name'] as String;
      final etaMinutes = _calculateETAMinutes(bus);
      
      return bus.copyWith(
        nextStop: nearestStopName.isNotEmpty ? nearestStopName : bus.nextStop,
        etaMinutes: etaMinutes,
      );
    }).toList();

    // Setup smooth animation for each bus
    for (final bus in buses) {
      if (bus.latitude == 0 && bus.longitude == 0) continue;
      
      final currentPos = _busCurrentPositions[bus.dbBusId] ?? bus.position;
      final newPos = bus.position;
      
      // Calculate bearing (direction bus is facing)
      if (currentPos != newPos) {
        _busBearings[bus.dbBusId] = _calculateBearing(currentPos, newPos);
      }
      
      // Set start position (current animated position or actual position)
      _busStartPositions[bus.dbBusId] = currentPos;
      // Set target position (new position from Supabase)
      _busTargetPositions[bus.dbBusId] = newPos;
      
      // Initialize current position if not set
      _busCurrentPositions[bus.dbBusId] ??= bus.position;
    }
    
    // Start smooth animation to new positions
    _startMarkerAnimation();

    setState(() {
      _buses = buses;
      _isLoading = false;
      _hasError = false;
      
      // Auto-select BUS-01 if available and nothing selected
      if (_selectedBus == null && buses.isNotEmpty) {
        _selectedBus = buses.firstWhere(
          (b) => b.displayId == 'BUS-01',
          orElse: () => buses.first,
        );
      }
      
      // Update selected bus with fresh data
      if (_selectedBus != null) {
        final updatedSelected = buses.firstWhere(
          (b) => b.dbBusId == _selectedBus!.dbBusId,
          orElse: () => _selectedBus!,
        );
        _selectedBus = updatedSelected;
      }
    });

    // On first load, center camera on BUS-01
    if (_isFirstLoad && buses.isNotEmpty) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final bus01 = buses.firstWhere(
          (b) => b.displayId == 'BUS-01',
          orElse: () => buses.first,
        );
        _centerOnBus(bus01);
      });
    }
  }

  /// Fallback to dummy data
  void _loadDummyBuses() {
    setState(() {
      _buses = BusModel.getDummyBuses();
      _isLoading = false;
      if (_buses.isNotEmpty && _selectedBus == null) {
        _selectedBus = _buses.first;
      }
    });
  }

  /// Center camera on a specific bus
  void _centerOnBus(BusModel bus) {
    if (_mapController != null && bus.latitude != 0 && bus.longitude != 0) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(bus.position, 16),
      );
    }
  }

  // ==================== SMOOTH ANIMATION METHODS ====================

  /// Called on each animation frame to update marker positions
  void _onMarkerAnimationTick() {
    if (!mounted) return;
    
    setState(() {
      for (final busId in _busTargetPositions.keys) {
        final start = _busStartPositions[busId];
        final end = _busTargetPositions[busId];
        if (start != null && end != null) {
          _busCurrentPositions[busId] = _lerpLatLng(
            start, 
            end, 
            _markerAnimationController.value,
          );
        }
      }
    });
  }

  /// Linearly interpolate between two LatLng positions
  LatLng _lerpLatLng(LatLng start, LatLng end, double t) {
    return LatLng(
      start.latitude + (end.latitude - start.latitude) * t,
      start.longitude + (end.longitude - start.longitude) * t,
    );
  }

  /// Calculate bearing (rotation angle) from one position to another
  double _calculateBearing(LatLng from, LatLng to) {
    final dLon = _toRadians(to.longitude - from.longitude);
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);

    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }

  /// Convert radians to degrees
  double _toDegrees(double radians) => radians * 180 / pi;

  /// Start smooth animation for all buses with new target positions
  void _startMarkerAnimation() {
    _markerAnimationController.reset();
    _markerAnimationController.forward();
  }

  Set<Polyline> _buildPolylines() {
    return _routeLines;
  }

  Set<Marker> _buildMarkers() {
    return _buses.map((bus) {
      // Skip if no valid coordinates
      if (bus.latitude == 0 && bus.longitude == 0) {
        return null;
      }
      
      // Use animated position if available, otherwise use actual position
      final animatedPosition = _busCurrentPositions[bus.dbBusId] ?? bus.position;
      final rotation = _busBearings[bus.dbBusId] ?? 0.0;
      
      return Marker(
        markerId: MarkerId(bus.dbBusId),
        position: animatedPosition,
        rotation: rotation,
        anchor: const Offset(0.5, 0.5), // Center the marker for proper rotation
        flat: true, // Flat marker rotates with the map
        icon: _busMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(_getMarkerHue(bus)),
        infoWindow: InfoWindow(
          title: bus.displayId,
          snippet: bus.isOnline 
              ? '${bus.speed.toInt()} km/h' 
              : 'Offline',
        ),
        onTap: () => _onBusSelected(bus),
      );
    }).whereType<Marker>().toSet();
  }

  double _getMarkerHue(BusModel bus) {
    if (!bus.isOnline) {
      return BitmapDescriptor.hueAzure; // Grey-ish for offline
    }
    switch (bus.status) {
      case BusStatus.onRoute:
        return BitmapDescriptor.hueGreen;
      case BusStatus.atStop:
        return BitmapDescriptor.hueBlue;
      case BusStatus.delayed:
        return BitmapDescriptor.hueOrange;
      case BusStatus.offline:
        return BitmapDescriptor.hueAzure;
    }
  }

  void _onBusSelected(BusModel bus) {
    setState(() {
      _selectedBus = bus;
    });
    _animateCameraToBus(bus);
  }

  void _animateCameraToBus(BusModel bus) {
    if (bus.latitude != 0 && bus.longitude != 0) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(bus.position, 16),
      );
    }
  }

  // ==================== ETA CALCULATIONS ====================
  
  /// Calculate ETA for a bus to the nearest stop
  /// Returns formatted string like "5 min", "<1 min", or "--"
  String _calculateETA(BusModel bus) {
    final nearestStopResult = _findNearestStopByPath(bus);
    final nearestStopDistance = nearestStopResult['distance'] as double;
    
    if (nearestStopDistance <= 0 || nearestStopDistance == double.infinity) {
      return '--';
    }

    final double busSpeed = bus.speed;
    // Use average speed if bus is stopped or moving slowly (< 3 km/h)
    final double effectiveSpeed = (busSpeed < 3.0) 
        ? ETAConstants.averageSpeedKmh 
        : busSpeed;

    if (effectiveSpeed <= 0) return '--';

    // Calculate time: Distance (km) / Speed (km/h) = Time (hours)
    final double timeInHours = nearestStopDistance / effectiveSpeed;
    final int timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes < 1) return '<1 min';
    if (timeInMinutes == 1) return '1 min';
    if (timeInMinutes > 120) return '${(timeInMinutes / 60).round()} jam';
    return '$timeInMinutes min';
  }

  /// Calculate ETA in minutes (for BusModel.etaMinutes)
  int? _calculateETAMinutes(BusModel bus) {
    final nearestStopResult = _findNearestStopByPath(bus);
    final nearestStopDistance = nearestStopResult['distance'] as double;
    
    if (nearestStopDistance <= 0 || nearestStopDistance == double.infinity) {
      return null;
    }

    final double busSpeed = bus.speed;
    final double effectiveSpeed = (busSpeed < 3.0) 
        ? ETAConstants.averageSpeedKmh 
        : busSpeed;

    if (effectiveSpeed <= 0) return null;

    final double timeInHours = nearestStopDistance / effectiveSpeed;
    final int timeInMinutes = (timeInHours * 60).round();

    return timeInMinutes < 1 ? 1 : timeInMinutes;
  }

  /// Get formatted distance string
  String _getFormattedDistance(BusModel bus) {
    final nearestStopResult = _findNearestStopByPath(bus);
    final nearestStopDistance = nearestStopResult['distance'] as double;

    if (nearestStopDistance <= 0 || nearestStopDistance == double.infinity) {
      return '--';
    }

    if (nearestStopDistance < 1.0) {
      return '${(nearestStopDistance * 1000).round()} m';
    }

    return '${nearestStopDistance.toStringAsFixed(1)} km';
  }

  /// Find the nearest bus stop using path-based distance calculation
  /// Returns a map with 'name' and 'distance'
  Map<String, dynamic> _findNearestStopByPath(BusModel bus) {
    if (bus.latitude == 0 || bus.longitude == 0) {
      return {'name': '', 'distance': 0.0};
    }

    final busLocation = LatLng(bus.latitude, bus.longitude);
    double minDistance = double.infinity;
    String nearestName = '';

    for (final stop in _busStopData) {
      final stopPosition = LatLng(stop['lat'] as double, stop['lng'] as double);
      final roadDistance = _calculatePathDistanceToStop(busLocation, stopPosition);

      // Skip stops that are extremely close (< 10 meters) - likely already passed
      if (roadDistance > 0.01 && roadDistance < minDistance) {
        minDistance = roadDistance;
        nearestName = stop['title'] as String;
      }
    }

    return {'name': nearestName, 'distance': minDistance};
  }

  /// Calculate path distance from bus to a stop using route polyline
  double _calculatePathDistanceToStop(LatLng busLocation, LatLng stopLocation) {
    final route = _getCurrentRoute();
    final busIndex = _findClosestRoutePointIndex(busLocation, route);
    final stopIndex = _findClosestRoutePointIndex(stopLocation, route);

    double routeDistance = _calculateRouteDistance(busIndex, stopIndex, route);

    // Add distance from bus to nearest route point
    final busToRoutePoint = _haversineDistance(
      busLocation.latitude, busLocation.longitude,
      route[busIndex].latitude, route[busIndex].longitude,
    );

    // Add distance from route point to stop
    final routePointToStop = _haversineDistance(
      route[stopIndex].latitude, route[stopIndex].longitude,
      stopLocation.latitude, stopLocation.longitude,
    );

    return routeDistance + busToRoutePoint + routePointToStop;
  }

  /// Get current route based on time of day
  List<LatLng> _getCurrentRoute() {
    // Morning route (before noon), afternoon route (after noon)
    if (DateTime.now().hour < 12) {
      // Extract points from morning polyline
      return _routeLines
          .firstWhere((p) => p.polylineId.value == 'rute_pagi')
          .points;
    } else {
      return _routeLines
          .firstWhere((p) => p.polylineId.value == 'rute_sore')
          .points;
    }
  }

  /// Find the index of the closest point on the route to a given location
  int _findClosestRoutePointIndex(LatLng location, List<LatLng> route) {
    int closestIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < route.length; i++) {
      final distance = _haversineDistance(
        location.latitude, location.longitude,
        route[i].latitude, route[i].longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }

    return closestIndex;
  }

  /// Calculate distance along the route between two indices
  double _calculateRouteDistance(int startIndex, int endIndex, List<LatLng> route) {
    if (startIndex < 0 || endIndex < 0 || 
        startIndex >= route.length || endIndex >= route.length) {
      return 0.0;
    }

    double totalDistance = 0.0;

    if (startIndex <= endIndex) {
      // Simple case: travel forward along route
      for (int i = startIndex; i < endIndex; i++) {
        totalDistance += _haversineDistance(
          route[i].latitude, route[i].longitude,
          route[i + 1].latitude, route[i + 1].longitude,
        );
      }
    } else {
      // Wrap around: bus is ahead of stop on circular route
      // Go to end of route
      for (int i = startIndex; i < route.length - 1; i++) {
        totalDistance += _haversineDistance(
          route[i].latitude, route[i].longitude,
          route[i + 1].latitude, route[i + 1].longitude,
        );
      }
      // Then from start to stop
      for (int i = 0; i < endIndex; i++) {
        totalDistance += _haversineDistance(
          route[i].latitude, route[i].longitude,
          route[i + 1].latitude, route[i + 1].longitude,
        );
      }
    }

    return totalDistance;
  }

  /// Haversine formula to calculate distance between two coordinates (in km)
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = 0.5 - cos(dLat) / 2 +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * (1 - cos(dLon)) / 2;
    return R * 2 * asin(sqrt(a));
  }

  /// Convert degrees to radians
  double _toRadians(double degree) => degree * pi / 180;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Full-screen Google Map
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              // Center on first bus after map is ready
              if (_buses.isNotEmpty) {
                final bus01 = _buses.firstWhere(
                  (b) => b.displayId == 'BUS-01',
                  orElse: () => _buses.first,
                );
                Future.delayed(const Duration(milliseconds: 500), () {
                  _centerOnBus(bus01);
                });
              }
            },
            polylines: _buildPolylines(),
            markers: {..._buildMarkers(), ..._buildBusStopMarkers()},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.white.withAlpha(180),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text('Loading fleet data...'),
                  ],
                ),
              ),
            ),

          // Error banner (if any)
          if (_hasError)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.airDanger,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.airDangerText.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: AppColors.airDangerText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: AppColors.airDangerText),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _hasError = false;
                          _isLoading = true;
                        });
                        _busStreamSubscription?.cancel();
                        _initBusStream();
                      },
                      child: Text('Retry', style: TextStyle(color: AppColors.airDangerText)),
                    ),
                  ],
                ),
              ),
            ),

          // Layer 2: Top Fleet Selector
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: _hasError ? 72 : 16),
              child: SizedBox(
                height: 64,
                child: _buses.isEmpty
                    ? const Center(
                        child: Text(
                          'No buses available',
                          style: TextStyle(color: AppColors.textLight),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _buses.length,
                        itemBuilder: (context, index) {
                          final bus = _buses[index];
                          return FleetSelectorCard(
                            bus: bus,
                            isSelected: _selectedBus?.dbBusId == bus.dbBusId,
                            onTap: () => _onBusSelected(bus),
                          );
                        },
                      ),
              ),
            ),
          ),

          // Refresh button (right side)
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + (_hasError ? 140 : 90),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.cardShadow,
              ),
              child: IconButton(
                onPressed: () {
                  // Refresh data manually
                  _busStreamSubscription?.cancel();
                  setState(() {
                    _isLoading = true;
                  });
                  _initBusStream();
                },
                icon: const Icon(Icons.refresh_rounded),
                color: AppColors.textMedium,
              ),
            ),
          ),

          // Layer 3: Draggable Bottom Bus Detail Panel (above navbar)
          if (_selectedBus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: kBottomNavigationBarHeight),
              child: DraggableScrollableSheet(
                initialChildSize: 0.35,  // 35% of available height
                minChildSize: 0.12,      // 12% - just the header visible
                maxChildSize: 0.75,      // 75% - leaves room for fleet selector
                snap: true,
                snapSizes: const [0.12, 0.35, 0.75],
                builder: (context, scrollController) {
                  return BusDetailPanel(
                    bus: _selectedBus!,
                    scrollController: scrollController,
                    onClose: () {
                      setState(() {
                        _selectedBus = null;
                      });
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
