import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/home_widget_config.dart';

class WidgetManagementScreen extends StatefulWidget {
  const WidgetManagementScreen({super.key});

  @override
  State<WidgetManagementScreen> createState() => _WidgetManagementScreenState();
}

class _WidgetManagementScreenState extends State<WidgetManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 기본 위젯 설정 (초기값)
  final List<HomeWidgetConfig> _defaultWidgets = [
    HomeWidgetConfig(id: 'urgent_notice', isVisible: true),
    HomeWidgetConfig(id: 'notice_search', isVisible: true), // NEW
    HomeWidgetConfig(id: 'important_notice', isVisible: true), // NEW
    HomeWidgetConfig(id: 'calendar', isVisible: true),
    HomeWidgetConfig(id: 'categories', isVisible: true),
    HomeWidgetConfig(id: 'hot_notice', isVisible: true),
  ];

  List<HomeWidgetConfig> _currentWidgets = [];
  bool _isLoading = true;

  // 위젯 ID와 표시 이름 매핑
  final Map<String, String> _widgetNames = {
    'urgent_notice': '긴급 공지',
    'notice_search': '공지사항 통합 검색', // NEW
    'important_notice': '중요 공지', // NEW
    'calendar': '오늘의 일정',
    'categories': '카테고리 메뉴',
    'hot_notice': '인기 공지사항',
  };

  @override
  void initState() {
    super.initState();
    _loadWidgetConfig();
  }

  void _loadWidgetConfig() {
    _firestoreService.getHomeWidgetConfig().listen((configMaps) {
      if (!mounted) return;

      setState(() {
        if (configMaps.isEmpty) {
          _currentWidgets = List.from(_defaultWidgets);
        } else {
          // Firestore에 저장된 설정 불러오기
          List<HomeWidgetConfig> loaded = configMaps
              .map((m) => HomeWidgetConfig.fromMap(m))
              .toList();

          // 혹시 나중에 추가된 새 위젯이 저장된 설정에 없을 경우를 대비해 병합
          // 1. 저장된 것 먼저 추가
          List<HomeWidgetConfig> merged = List.from(loaded);

          // 2. 누락된 기본 위젯 추가 (맨 뒤에)
          for (var def in _defaultWidgets) {
            if (!merged.any((w) => w.id == def.id)) {
              merged.add(def);
            }
          }

          // 3. 더 이상 사용되지 않는 위젯 ID 제거 (필요시)
          // merged.removeWhere((w) => !_widgetNames.containsKey(w.id));

          _currentWidgets = merged;
        }
        _isLoading = false;
      });
    });
  }

  void _saveConfig() {
    final List<Map<String, dynamic>> configMaps = _currentWidgets
        .map((w) => w.toMap())
        .toList();
    _firestoreService.saveHomeWidgetConfig(configMaps);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '홈 위젯 관리',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: const Color(0xFFF2F4F6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: Color(0xFF8B95A1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "홈 화면에서 위젯을 꾹 눌러 순서를 변경할 수 있어요.",
                          style: const TextStyle(
                            color: Color(0xFF8B95A1),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      for (int i = 0; i < _currentWidgets.length; i++)
                        _buildListItem(i, _currentWidgets[i]),
                    ],
                    onReorder: (int oldIndex, int newIndex) {
                      setState(() {
                        if (oldIndex < newIndex) {
                          newIndex -= 1;
                        }
                        final item = _currentWidgets.removeAt(oldIndex);
                        _currentWidgets.insert(newIndex, item);
                      });
                      _saveConfig(); // 순서 변경 즉시 저장
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildListItem(int index, HomeWidgetConfig widgetConfig) {
    return Container(
      key: Key(widgetConfig.id),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E8EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: const Icon(
          Icons.drag_handle_rounded,
          color: Color(0xFFB0B8C1),
        ),
        title: Text(
          _widgetNames[widgetConfig.id] ?? widgetConfig.id,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333D4B),
          ),
        ),
        trailing: Switch(
          value: widgetConfig.isVisible,
          activeColor: const Color(0xFF3182F6),
          onChanged: (bool value) {
            setState(() {
              _currentWidgets[index] = HomeWidgetConfig(
                id: widgetConfig.id,
                isVisible: value,
              );
            });
            _saveConfig(); // 토글 변경 즉시 저장
          },
        ),
      ),
    );
  }
}
