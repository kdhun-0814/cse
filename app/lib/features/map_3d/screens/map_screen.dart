import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/map_service.dart'; // Import MapService
import '../services/path_service.dart'; // Import PathService
import '../../../utils/toast_utils.dart';
import '../../../widgets/common/custom_loading_indicator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapService _mapService = MapService();
  final PathService _pathService = PathService();

  // Data State
  String? _modelUrl;
  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];

  // Navigation State
  Room? _startRoom;
  Room? _endRoom;
  List<PathPoint> _currentPath = [];
  bool _isNavigating = false;

  // UI State
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  // Camera Control
  String _cameraTarget = '20m 0m 0m';
  String _cameraOrbit =
      '0deg 90deg 80m'; // Top-down view to match floor plan image

  // Debug State
  bool _isDebugMode = false;
  double _debugX = 0;
  double _debugZ = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final url = await _mapService.getMapModelUrl();

    // Fetch Graph Data
    final rooms = await _mapService.loadRooms();
    final edges = await _mapService.fetchEdges();

    // Initialize Pathfinding Graph
    _pathService.buildGraph(rooms, edges);

    if (mounted) {
      setState(() {
        _modelUrl = url;
        _allRooms = rooms;
        _filteredRooms = rooms;
        _isLoading = false;

        // Default Start: Fixed to 'Elevator' (passenger)
        try {
          _startRoom = rooms.firstWhere(
            (r) => r.name == 'Elevator', // Explicitly look for 'Elevator'
            orElse: () => rooms.firstWhere(
              (r) => r.name.contains('Elevator'),
              orElse: () => rooms.first,
            ),
          );
        } catch (_) {}
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      _filteredRooms = _allRooms
          .where(
            (room) =>
                room.name.contains(query) || room.description.contains(query),
          )
          .toList();
    });
  }

  void _onRoomSelected(Room room) {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSearching = false;
      _searchController.text = room.name;
      _endRoom = room;
      _isNavigating = true; // Enable navigation mode UI

      // Auto-calculate path if start is set
      if (_startRoom != null) {
        _calculateAndShowPath();
      } else {
        // Just fly to destination
        _flyToRoom(room);
      }
    });
  }

  void _flyToRoom(Room room) {
    setState(() {
      // Coordinate mapping: JSON (x, z) -> Viewer (x, 0, z)
      // Assuming Y in JSON is 0 and Z is Depth.
      _cameraTarget = '${room.x}m 0m ${room.z}m';
      _cameraOrbit = '0deg 45deg 20m'; // Closer zoom
    });

    ToastUtils.show(context, "${room.name}로 이동합니다.");
  }

  void _calculateAndShowPath() {
    if (_startRoom == null || _endRoom == null) return;

    final path = _pathService.calculatePath(_startRoom!, _endRoom!);
    setState(() {
      _currentPath = path;
      // Camera: Midpoint zoom
      double midX = (_startRoom!.x + _endRoom!.x) / 2;
      double midZ = (_startRoom!.z + _endRoom!.z) / 2;
      _cameraTarget = '${midX}m 0m ${midZ}m';
      _cameraOrbit = '0deg 60deg 60m'; // Overview
    });
  }

  @override
  Widget build(BuildContext context) {
    // HTML Generation for Hotspots
    // We create a simpler inner_html string to pass to ModelViewer
    // Note: ModelViewerPlus uses `innerModelViewerHtml` or just slots.
    // The package `model_viewer_plus` exposes `innerModelViewerHtml`.
    // Let's construct the HTML for hotspots.

    StringBuffer htmlBuffer = StringBuffer();

    // Debug Marker
    if (_isDebugMode) {
      htmlBuffer.write(
        '<button slot="hotspot-debug" '
        'data-position="${_debugX}m 1m ${_debugZ}m" '
        'data-normal="0m 1m 0m" '
        'style="display: block; width: 20px; height: 20px; border-radius: 50%; border: 2px solid white; background-color: #ff0000; opacity: 1.0;">'
        '</button>',
      );
    }

    int i = 0;
    for (var p in _currentPath) {
      // Slot name: hotspot-i
      // Coord: x y z
      // We use JSON z as Viewer z (since JSON y is 0).
      // Check mapping: If JSON x,y,z -> Viewer x,y,z directly?
      // JSON y=0. If we map JSON z -> Viewer z: (p.x, 0, p.z)
      // Adjust Height: Lift dots slightly (y=1m) so they don't clip floor
      htmlBuffer.write(
        '<button slot="hotspot-path-$i" '
        'data-position="${p.x}m 1m ${p.z}m" '
        'data-normal="0m 1m 0m" '
        'style="display: block; width: 10px; height: 10px; border-radius: 50%; border: none; background-color: #3182F6; opacity: 0.8;">'
        '</button>',
      );
      i++;
    }

    // Add Start/End markers (larger)
    if (_endRoom != null) {
      htmlBuffer.write(
        '<button slot="hotspot-end" '
        'data-position="${_endRoom!.x}m 2m ${_endRoom!.z}m" '
        'data-normal="0m 1m 0m" '
        'style="display: block; padding: 5px; border-radius: 10px; border: none; background-color: #ef4444; color: white; font-weight: bold;">'
        '도착: ${_endRoom!.name}'
        '</button>',
      );
    }
    if (_startRoom != null && _isNavigating) {
      htmlBuffer.write(
        '<button slot="hotspot-start" '
        'data-position="${_startRoom!.x}m 2m ${_startRoom!.z}m" '
        'data-normal="0m 1m 0m" '
        'style="display: block; padding: 5px; border-radius: 10px; border: none; background-color: #22c55e; color: white; font-weight: bold;">'
        '출발'
        '</button>',
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('컴퓨터공학과 4층 맵'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () {
          setState(() {
            _isDebugMode = !_isDebugMode;
            if (_isDebugMode) {
              _debugX = 0;
              _debugZ = 0;
              _cameraTarget = '0m 0m 0m';
              _cameraOrbit = '0deg 90deg 100m'; // Zoom out
              ToastUtils.show(context, "좌표 보정 모드 ON");
            }
          });
        },
        child: Icon(
          _isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
        ),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CustomLoadingIndicator())
          else if (_modelUrl == null || _modelUrl!.isEmpty)
            const Center(child: Text("맵 로딩 실패"))
          else
            ModelViewer(
              key: ValueKey(
                "$_cameraTarget${_currentPath.length}",
              ), // Rebuild only on significant changes
              backgroundColor: const Color(0xFFF0F0F0),
              src: _modelUrl!,
              alt: "CSE Map",
              ar: true,
              autoRotate: !_isNavigating,
              cameraControls: true,
              cameraTarget: _cameraTarget,
              cameraOrbit: _cameraOrbit,
              innerModelViewerHtml: htmlBuffer.toString(),
            ),

          // Search Bar
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "도착지 검색 (예: 401)",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isNavigating
                          ? IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isNavigating = false;
                                  _endRoom = null;
                                  _currentPath = [];
                                  _searchController.clear();
                                  _cameraOrbit = '0deg 45deg 50m'; // Reset view
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(15),
                    ),
                  ),
                ),
                if (_isSearching && _filteredRooms.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 10),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredRooms.length,
                      itemBuilder: (ctx, i) => ListTile(
                        title: Text(_filteredRooms[i].name),
                        subtitle: Text(_filteredRooms[i].description),
                        onTap: () => _onRoomSelected(_filteredRooms[i]),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Navigation Panel (Bottom)
          if (_isNavigating && _endRoom != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "길찾기 설정",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: Colors.green),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "현재 위치: ${_startRoom?.name ?? '엘리베이터'}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 1,
                      color: Colors.grey[200],
                      margin: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.red),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _endRoom!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3182F6),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.directions_run),
                        label: const Text("안내 시작"),
                        onPressed: _calculateAndShowPath,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Debug Panel
          if (_isDebugMode)
            Positioned(
              bottom: 80, // Above navigation panel if shown
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    Text(
                      "X: ${_debugX.toStringAsFixed(2)} | Z: ${_debugZ.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        const Text("X", style: TextStyle(color: Colors.white)),
                        Expanded(
                          child: Slider(
                            value: _debugX,
                            min: -100,
                            max: 100,
                            onChanged: (val) {
                              setState(() {
                                _debugX = val;
                                _cameraTarget = '${_debugX}m 0m ${_debugZ}m';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Z", style: TextStyle(color: Colors.white)),
                        Expanded(
                          child: Slider(
                            value: _debugZ,
                            min: -100,
                            max: 100,
                            onChanged: (val) {
                              setState(() {
                                _debugZ = val;
                                _cameraTarget = '${_debugX}m 0m ${_debugZ}m';
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
