import '../models/floor_config.dart';

class FloorConfigs {
  static const FloorConfig floor4 = FloorConfig(
    floor: 4,
    floorName: '4층',
    glbPath: 'assets/3d/4floor.glb',
    jsonPath: 'assets/json/floor_4.json',
    initialCameraOrbit: '0deg 30deg 1250m',
    initialCameraTarget: '0m 0m 0m', // 중심 좌표 (0,0,0)
    defaultZoom: 250,
  );

  static const FloorConfig floor5 = FloorConfig(
    floor: 5,
    floorName: '5층',
    glbPath: 'assets/3d/5floor.glb',
    jsonPath: 'assets/json/floor_5.json',
    initialCameraOrbit: '0deg 30deg 1200m',
    initialCameraTarget: '-25m 0m 0m',
    defaultZoom: 250,
  );

  static const FloorConfig floor6 = FloorConfig(
    floor: 6,
    floorName: '6층',
    glbPath: 'assets/3d/6floor.glb',
    jsonPath: 'assets/json/floor_6.json',
    initialCameraOrbit: '0deg 30deg 1200m',
    initialCameraTarget: '-25m 0m 0m',
    defaultZoom: 250,
  );

  static const FloorConfig floor7 = FloorConfig(
    floor: 7,
    floorName: '7층',
    glbPath: 'assets/3d/7floor.glb',
    jsonPath: 'assets/json/floor_7.json',
    initialCameraOrbit: '0deg 30deg 1200m',
    initialCameraTarget: '-25m 0m 0m',
    defaultZoom: 250,
  );

  static const List<FloorConfig> allFloors = [floor4, floor5, floor6, floor7];

  static FloorConfig getConfig(int floor) {
    return allFloors.firstWhere(
      (config) => config.floor == floor,
      orElse: () => floor4,
    );
  }
}
