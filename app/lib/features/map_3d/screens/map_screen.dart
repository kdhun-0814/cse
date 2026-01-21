import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../services/map_service.dart';
import '../services/path_service.dart';

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

  // Debug State
  bool _isDebugMode = false;
  double _debugX = 0;
  double _debugZ = 0;

  // Camera Control
  String _cameraTarget = '20m 0m 0m';
  String _cameraOrbit =
      '0deg 60deg 80m'; // Top-down but tilted (60deg pitch), Front view (0deg)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // 1. Fetch Model URL
    _modelUrl = await _mapService.getMapModelUrl();

    // 2. Load Nodes
    _allRooms = await _mapService.loadRooms();

    // 3. Load Edges & Build Graph
    final edges = await _mapService.fetchEdges();
    _pathService.buildGraph(_allRooms, edges);

    // 4. Set Default Start (Elevator/Enterance)
    // Try finding a node named "엘리베이터" or use first node as fallback
    try {
      _startRoom = _allRooms.firstWhere((r) => r.name.contains("엘리베이터"));
    } catch (_) {
      if (_allRooms.isNotEmpty) _startRoom = _allRooms.first;
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredRooms = [];
      } else {
        _filteredRooms = _allRooms.where((room) {
          final nameMatch = room.name.toLowerCase().contains(
            query.toLowerCase(),
          );
          final descMatch = room.description.toLowerCase().contains(
            query.toLowerCase(),
          );
          return nameMatch || descMatch;
        }).toList();
      }
    });
  }

  void _onRoomSelected(Room room) {
    setState(() {
      _endRoom = room;
      _isSearching = false;
      _searchController.text = room.name;
      _filteredRooms = [];

      // Focus camera on selected room temporarily?
      // Or just wait for "Start Navigation"
      _cameraTarget = '${room.x}m ${room.y}m ${room.z}m';
    });
    FocusScope.of(context).unfocus(); // Cloud keyboard
  }

  void _calculateAndShowPath() {
    if (_startRoom == null || _endRoom == null) return;

    final path = _pathService.calculatePath(_startRoom!, _endRoom!);
    setState(() {
      _currentPath = path;
      _isNavigating = true;

      // Adjust camera to view the path?
      // Optional: Center between start and end
      double midX = (_startRoom!.x + _endRoom!.x) / 2;
      double midZ = (_startRoom!.z + _endRoom!.z) / 2;
      _cameraTarget = '${midX}m 0m ${midZ}m';
    });
  }

  String _buildHtmlBuffer() {
    if (_currentPath.isEmpty) return '';

    StringBuffer buffer = StringBuffer();
    // Add CSS for hotspots
    buffer.writeln('<style>');
    buffer.writeln(
      '.hotspot { display: block; width: 8px; height: 8px; border-radius: 50%; border: none; background-color: #FF0000; box-shadow: 0 0 2px black; pointer-events: none; }',
    );
    buffer.writeln(
      '.start-point { background-color: #00FF00; width: 12px; height: 12px; z-index: 10; }',
    );
    buffer.writeln(
      '.end-point { background-color: #0000FF; width: 12px; height: 12px; z-index: 10; }',
    );
    buffer.writeln('</style>');

    for (int i = 0; i < _currentPath.length; i++) {
      final point = _currentPath[i];

      // Downsample points for performance/visuals
      if (i > 0 && i < _currentPath.length - 1 && i % 2 != 0) continue;

      String className = 'hotspot';
      if (i == 0) className += ' start-point';
      if (i == _currentPath.length - 1) className += ' end-point';

      buffer.writeln(
        '<button class="$className" slot="hotspot-$i" '
        'data-position="${point.x}m ${point.y}m ${point.z}m" '
        'data-normal="0m 1m 0m"></button>',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Generate inner HTML for path visualization
    final htmlBuffer = _buildHtmlBuffer();

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // 3D Model Viewer
                if (_modelUrl != null && _modelUrl!.isNotEmpty)
                  ModelViewer(
                    key: ValueKey(
                      "$_cameraTarget${_currentPath.length}",
                    ), // Rebuild on target/path change
                    backgroundColor: const Color(0xFFF0F0F0),
                    src: _modelUrl!,
                    alt: "CSE Map",
                    ar: true,
                    autoRotate: !_isNavigating,
                    rotationPerSecond: "20deg", // Faster rotation
                    cameraControls: true,
                    cameraTarget: _cameraTarget,
                    cameraOrbit: _cameraOrbit,
                    innerModelViewerHtml: htmlBuffer,
                  )
                else
                  const Center(child: Text("Failed to load map model")),

                // Search Bar
                Positioned(
                  top: 50, // Adjusted for SafeArea
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
                            suffixIcon:
                                _isNavigating ||
                                    _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _isNavigating = false;
                                        _endRoom = null;
                                        _currentPath = [];
                                        _searchController.clear();
                                        _filteredRooms = [];
                                        _cameraOrbit =
                                            '0deg 60deg 80m'; // Reset view
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
                            padding: EdgeInsets.zero,
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
                    bottom: 30,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 15),
                        ],
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
                              const Icon(
                                Icons.my_location,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "현재 위치: ${_startRoom?.name ?? '엘리베이터'}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.directions_run),
                              label: const Text("안내 시작"),
                              onPressed: _currentPath.isEmpty
                                  ? _calculateAndShowPath
                                  : null, // Disable if already showing path? Or allow re-calc
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Debug Panel (Hidden by default)
                if (_isDebugMode)
                  Positioned(
                    bottom: 180,
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
                              const Text(
                                "X",
                                style: TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _debugX,
                                  min: -100,
                                  max: 100,
                                  onChanged: (val) {
                                    setState(() {
                                      _debugX = val;
                                      _cameraTarget =
                                          '${_debugX}m 0m ${_debugZ}m';
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Text(
                                "Z",
                                style: TextStyle(color: Colors.white),
                              ),
                              Expanded(
                                child: Slider(
                                  value: _debugZ,
                                  min: -100,
                                  max: 100,
                                  onChanged: (val) {
                                    setState(() {
                                      _debugZ = val;
                                      _cameraTarget =
                                          '${_debugX}m 0m ${_debugZ}m';
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
