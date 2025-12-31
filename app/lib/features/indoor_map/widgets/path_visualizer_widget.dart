import 'dart:math';
import '../models/path_node.dart';

class PathVisualizerWidget {
  /// 연결된 점선 경로 시각화
  static String buildPathHotspots(List<PathNode> path) {
    if (path.isEmpty) return '';

    StringBuffer html = StringBuffer();

    // 경로 노드들 사이를 보간하여 연결된 점선 생성
    List<Map<String, double>> interpolatedPoints = _interpolatePath(path);

    // 점선 효과 (5개 중 1개만 표시 - 부드러운 간격)
    for (int i = 0; i < interpolatedPoints.length; i++) {
      if (i % 5 == 0) {
        final point = interpolatedPoints[i];
        html.write('''
          <div slot="hotspot-path-$i"
            data-position="${point['x']}m ${point['y']}m ${point['z']}m"
            data-normal="0m 1m 0m"
            style="width: 15px; height: 15px; 
                   border-radius: 50%; 
                   background: rgba(96, 165, 250, 0.95); 
                   pointer-events: none;
                   box-shadow: 0 0.15m 0.5m rgba(96, 165, 250, 0.4);">
          </div>
        ''');
      }
    }

    // 출발 마커 (부드러운 초록색 캡슐)
    if (path.isNotEmpty) {
      final start = path.first;
      // 노드 높이 + 약간의 오프셋 (잘 보이게)
      final h = start.z + 1.5;

      html.write('''
        <div slot="hotspot-start"
          data-position="${start.x}m ${h}m ${-start.y}m"
          data-normal="0m 1m 0m"
          style="background: rgba(52, 211, 153, 0.95); 
                 color: white; 
                 padding: 0.65m 1.3m; 
                 border-radius: 1.8m;
                 font-weight: 600; 
                 font-size: 0.85m;
                 box-shadow: 0 0.35m 1m rgba(52, 211, 153, 0.4);
                 text-align: center;
                 line-height: 1;
                 white-space: nowrap;
                 pointer-events: none;">
          🚀 출발 (EV)
        </div>
      ''');
    }

    // 도착 마커 (부드러운 빨간색 캡슐)
    if (path.length > 1) {
      final end = path.last;
      final h = end.z + 1.5;

      html.write('''
        <div slot="hotspot-end"
          data-position="${end.x}m ${h}m ${-end.y}m"
          data-normal="0m 1m 0m"
          style="background: rgba(248, 113, 113, 0.95); 
                 color: white; 
                 padding: 0.65m 1.3m; 
                 border-radius: 1.8m;
                 font-weight: 600; 
                 font-size: 0.85m;
                 box-shadow: 0 0.35m 1m rgba(248, 113, 113, 0.4);
                 text-align: center;
                 line-height: 1;
                 white-space: nowrap;
                 pointer-events: none;">
          📍 도착 (${end.name ?? ''})
        </div>
      ''');
    }

    return html.toString();
  }

  /// 경로 노드들 사이를 보간하여 연결된 점들 생성
  static List<Map<String, double>> _interpolatePath(List<PathNode> path) {
    List<Map<String, double>> interpolated = [];
    const double stepSize = 8.0; // 8m 간격으로 점 생성

    for (int i = 0; i < path.length - 1; i++) {
      final start = path[i];
      final end = path[i + 1];

      final dx = end.x - start.x;
      final dy = end.y - start.y;
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < 0.1) continue;

      final steps = max(2, (distance / stepSize).ceil());

      for (int j = 0; j < steps; j++) {
        final t = j / steps;
        // z값(높이)도 가져와서 사용 (점선은 노드 높이 그대로)
        interpolated.add({
          'x': start.x + dx * t,
          'y': start.z, // 높이 값 사용 (3D Model Y축)
          'z': -(start.y + dy * t), // 2D Y -> 3D Z (음수)
        });
      }
    }

    if (path.isNotEmpty) {
      final last = path.last;
      interpolated.add({'x': last.x, 'y': last.z, 'z': -last.y});
    }

    return interpolated;
  }
}
