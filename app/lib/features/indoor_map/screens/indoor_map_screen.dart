import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import '../constants/floor_configs.dart';
import '../models/floor_config.dart';
import '../models/path_node.dart';
import '../models/floor_data.dart';
import '../models/room_search_result.dart';
import '../services/floor_data_service.dart';
import '../services/navigation_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/floor_selector_widget.dart';
import '../widgets/path_visualizer_widget.dart';
import '../../../widgets/common/custom_loading_indicator.dart';

class IndoorMapScreen extends StatefulWidget {
  const IndoorMapScreen({super.key});

  @override
  State<IndoorMapScreen> createState() => _IndoorMapScreenState();
}

class _IndoorMapScreenState extends State<IndoorMapScreen> {
  final FloorDataService _floorDataService = FloorDataService();
  final NavigationService _navigationService = NavigationService();

  // 데이터 상태
  FloorData? _currentFloorData; // 현재 층 데이터
  List<RoomSearchResult> _allSearchableRooms = []; // 전체 층 검색용 리스트

  late FloorConfig _currentConfig;
  bool _isLoading = true;
  String? _errorMessage;

  // 내비게이션 상태
  PathNode? _startNode;
  PathNode? _selectedRoom;
  List<PathNode> _currentPath = [];

  // UI 상태
  late String _cameraOrbit;
  late String _cameraTarget;
  bool _isFloorSwitching = false;

  @override
  void initState() {
    super.initState();
    _currentConfig = FloorConfigs.floor4;
    _cameraOrbit = _currentConfig.initialCameraOrbit;
    _cameraTarget = _currentConfig.initialCameraTarget;
    _initalizeAllData();
  }

  // 모든 층 데이터 로드 및 초기화
  Future<void> _initalizeAllData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. 모든 층 데이터 병렬 로드
      final futures = FloorConfigs.allFloors.map((config) async {
        final data = await _floorDataService.loadFloorData(
          config.floor,
          config.jsonPath,
        );
        return MapEntry(config, data);
      });

      final results = await Future.wait(futures);

      // 2. 검색용 통합 리스트 생성
      List<RoomSearchResult> allRooms = [];
      for (var entry in results) {
        final config = entry.key;
        final data = entry.value;

        final roomNodes = data.getRoomNodes();
        for (var node in roomNodes) {
          allRooms.add(
            RoomSearchResult(
              node: node,
              floor: config.floor,
              floorName: config.floorName,
            ),
          );
        }
      }

      // 3. 현재 층 데이터 설정 (초기 4층)
      final initialData = results
          .firstWhere((e) => e.key.floor == _currentConfig.floor)
          .value;

      if (!mounted) return;
      setState(() {
        _allSearchableRooms = allRooms;
        _currentFloorData = initialData;
        _startNode = initialData.getStartNode();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // 층만 변경 (데이터는 이미 로드됨)
  Future<void> _switchFloor(int floor, {VoidCallback? onBeforeFadeIn}) async {
    if (floor == _currentConfig.floor) return;

    // 1. 전환 시작 (페이드 아웃)
    setState(() {
      _isFloorSwitching = true;
    });
    await Future.delayed(const Duration(milliseconds: 300));

    final newConfig = FloorConfigs.getConfig(floor);
    // 캐시된 데이터 가져오기 (이미 로드됨)
    final newData = await _floorDataService.loadFloorData(
      floor,
      newConfig.jsonPath,
    );

    setState(() {
      _currentConfig = newConfig;
      _currentFloorData = newData;
      _startNode = newData.getStartNode();

      // 카메라 초기화
      _cameraOrbit = newConfig.initialCameraOrbit;
      _cameraTarget = newConfig.initialCameraTarget;

      // 선택/경로 초기화 (다른 층으로 가면 초기화)
      _selectedRoom = null;
      _currentPath = [];
    });

    // 2. 추가 작업 (예: 검색 결과로 이동하여 카메라 설정)
    if (onBeforeFadeIn != null) {
      onBeforeFadeIn();
    }

    // 3. 모델 로딩 시간 확보 (깜빡임 방지)
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. 전환 종료 (페이드 인)
    setState(() {
      _isFloorSwitching = false;
    });
  }

  void _onRoomSelected(RoomSearchResult result) async {
    // 1. 다른 층이면 해당 층으로 먼저 이동
    if (result.floor != _currentConfig.floor) {
      await _switchFloor(
        result.floor,
        onBeforeFadeIn: () => _updateRoomSelection(result),
      );
    } else {
      // 2. 같은 층이어도 부드러운 전환 효과 적용
      setState(() {
        _isFloorSwitching = true;
      });
      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted) return;
      _updateRoomSelection(result);

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _isFloorSwitching = false;
      });
    }
  }

  void _updateRoomSelection(RoomSearchResult result) {
    if (_startNode == null || _currentFloorData == null) return;

    setState(() {
      _selectedRoom = result.node;

      // 2. BFS로 경로 찾기 (현재 층 데이터 사용)
      _currentPath = _navigationService.findPath(
        _startNode!,
        result.node,
        _currentFloorData!,
      );
    });
  }

  void _onClearSearch() {
    setState(() {
      _selectedRoom = null;
      _currentPath = [];
      _cameraTarget = _currentConfig.initialCameraTarget;
      _cameraOrbit = _currentConfig.initialCameraOrbit;
    });
  }

  void _onFloorTap(int floor) {
    _switchFloor(floor);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
        automaticallyImplyLeading: false, // 뒤로가기 버튼 자동 생성 방지
        title: Text(
          '${_currentConfig.floorName} 실내 지도',
          style: const TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CustomLoadingIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildMapView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('데이터 로드 실패', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initalizeAllData,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentFloorData == null) {
      return const Center(child: Text('데이터가 없습니다.'));
    }

    return Stack(
      children: [
        // Layer 1: 3D Model Viewer
        ModelViewer(
          key: ValueKey(
            'map-${_currentConfig.floor}-${_selectedRoom?.name ?? "none"}-${_currentPath.length}',
          ), // Key 변경으로 갱신 유도
          backgroundColor: const Color(0xFFF0F0F0),
          src: _currentConfig.glbPath,
          alt: _currentConfig.floorName,
          ar: false,
          autoRotate: false,
          cameraControls: true,
          cameraOrbit: _cameraOrbit,
          cameraTarget: _cameraTarget,
          innerModelViewerHtml: _currentPath.isNotEmpty
              ? PathVisualizerWidget.buildPathHotspots(_currentPath)
              : '',
        ),

        // Layer 1.5: Transition Overlay (부드러운 전환 효과)
        IgnorePointer(
          ignoring: !_isFloorSwitching,
          child: AnimatedOpacity(
            opacity: _isFloorSwitching ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              color: const Color(0xFFF2F4F6),
              child: const Center(child: CustomLoadingIndicator()),
            ),
          ),
        ),

        // Layer 2: Search Bar (Global Search - Centered)
        Positioned(
          top: 16,
          left: 16,
          right: 16, // 양쪽 여백을 동일하게 주어 중앙 정렬 효과
          child: SearchBarWidget(
            allRooms: _allSearchableRooms,
            onRoomSelected: _onRoomSelected,
            onClear: _onClearSearch,
          ),
        ),

        // Layer 3: Floor Selector
        if (_selectedRoom == null) // ★ 검색 결과가 없을 때만 층 선택 위젯 표시
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FloorSelectorWidget(
                currentFloor: _currentConfig.floor,
                onFloorChanged: _onFloorTap,
              ),
            ),
          ),

        // Bottom Info Panel
        if (_selectedRoom != null)
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _buildRoomInfoCard(),
          ),
      ],
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3182F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, color: Color(0xFF3182F6)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedRoom!.name ?? 'Unknown',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  '${_currentConfig.floorName}에 위치함',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _onClearSearch,
            icon: const Icon(Icons.close, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
