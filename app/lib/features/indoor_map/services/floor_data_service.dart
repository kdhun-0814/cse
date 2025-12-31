import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/floor_data.dart';

class FloorDataService {
  // 싱글톤 패턴
  static final FloorDataService _instance = FloorDataService._internal();
  factory FloorDataService() => _instance;
  FloorDataService._internal();

  final Map<int, FloorData> _cache = {};

  /// 해당 층의 데이터 로드
  Future<FloorData> loadFloorData(int floor, String jsonPath) async {
    if (_cache.containsKey(floor)) {
      return _cache[floor]!;
    }

    try {
      final String jsonString = await rootBundle.loadString(jsonPath);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final floorData = FloorData.fromJson(jsonData);
      _cache[floor] = floorData;
      return floorData;
    } catch (e) {
      throw Exception('Failed to load floor $floor data: $e');
    }
  }

  /// 캐시 초기화
  void clearCache() {
    _cache.clear();
  }
}
